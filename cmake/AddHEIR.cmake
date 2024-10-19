include_guard()

# Make MLIR/LLVM CMake helper functions available
list(APPEND CMAKE_MODULE_PATH "${MLIR_CMAKE_DIR}")
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddMLIR)
include(AddLLVM)
include(TableGen)

# tablegen dialect helper "template"
# For a dialect_name ABC and file_suffix Suffix it checks if ABCSuffix.td exists and if so,
# generates the corresponding .h.inc and .cpp.inc files using -gen-cmd-declcs / -gen-cmd-defs
# It adds ABC_CopyHeaders as a depenceny of the new tablegen target ABC_SuffixIncGen
# and adds the new tablegen target as a dependency of ABC_AllIncGen
macro(heir_dialect_tablegen dialect_name file_suffix cmd)
  if(EXISTS "${original_current_source_dir}/${dialect_name}${file_suffix}.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}${file_suffix}.td)
    mlir_tablegen(${dialect_name}${file_suffix}.h.inc
                  -gen-${cmd}-decls
                  -dialect=${dialect_namespace}
                  EXTRA_INCLUDES
                  ${dialect_include_dirs}
                )
    mlir_tablegen(${dialect_name}${file_suffix}.cpp.inc
                   -gen-${cmd}-defs
                   -dialect=${dialect_namespace}
                  EXTRA_INCLUDES
                  ${dialect_include_dirs}
                  )
    add_public_tablegen_target(${dialect_target}_${file_suffix}IncGen)
    add_dependencies(${dialect_target}_${file_suffix}IncGen ${dialect_target}_CopyHeaders)
    add_dependencies(${dialect_target}_AllIncGen ${dialect_target}_${file_suffix}IncGen)
  endif()
endmacro()


# custom helper for HEIR Dialects that follow our naming conventions
# This effectively behaves like a combination of add_mlir_dialect (tablegen
# and add_mlir_dialect_library (C++ library) from MLIR's AddMLIR.cmake module
#
# In addition to the explicit arguments, it takes the usual syntax of add_mlir_library
# and forwards them to add_mlir_dialect_library. TODO (build): create custom macros instead
#
# While it's generally a really bad idea to try and "forward" arguments to a CMake macro
# (bad things happen to lists, see https://gitlab.kitware.com/cmake/cmake/-/issues/22157),
# the MLIR/LLVM macros already do this internally quite a bit so it should be safe to do
# unless something changes with the macros in AddMLIR.cmake / AddLLVM.cmake upstream
function(add_AUTOMAGIC_heir_dialect dialect_name dialect_namespace)

  # Name of the dialect target (actual target will be created later)
  set(dialect_target "heir__Dialect__${dialect_name}")

  # Bazel-style copying of sources to a new target-specific binary directory
  # if we're not doing an in-source build
  # (i.e., the source and build directories are different),
  # Create all tablegen in a target-specific build directory
  set(original_current_binary_dir ${CMAKE_CURRENT_BINARY_DIR})
  set(original_current_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
  if(NOT ${original_current_source_dir} STREQUAL ${original_current_binary_dir})
    # get the relative path from the source directory to the current directory
    file(RELATIVE_PATH cur_src_dir_rel ${CMAKE_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR})
    # create a target-specific build directory at CMAKE_BINARY_DIR/TARGET/cur_src_dir_rel
    set(custom_binary_dir_prefix ${CMAKE_BINARY_DIR}/target_include/${dialect_target})
    set(custom_binary_dir ${custom_binary_dir_prefix}/${cur_src_dir_rel})
    set(CMAKE_CURRENT_BINARY_DIR ${custom_binary_dir})
    set(CMAKE_CURRENT_SOURCE_DIR ${custom_binary_dir})
    message(STATUS "Creating custom binary directory for ${dialect_target} at ${custom_binary_dir}")
  endif()

  # TODO: Grab the list of dependencies passed in and grab all their include directories
  set(dialect_include_dirs  ${custom_binary_dir_prefix}) # FIXME
  message(STATUS "Dialect include dirs for ${dialect_name}: ${dialect_include_dirs}")

  # Copy Headers/etc to ${custom_binary_dir}
  # Yes, globbing is bad, but we're doing this just for
  # Ninja's overly picky dependency graph tracking,
  # i.e., to define the "BYPRODUCTS" of the custom target
  file(GLOB dialect_files LIST_DIRECTORIES false RELATIVE ${original_current_source_dir} ${original_current_source_dir}/*)
  list(TRANSFORM dialect_files PREPEND ${custom_binary_dir}/)
  add_custom_target(${dialect_target}_CopyHeaders
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${original_current_source_dir} ${custom_binary_dir}/
    BYPRODUCTS ${dialect_files}
    COMMENT "Copying files from ${original_current_source_dir} to ${custom_binary_dir}"
  )

  # TableGen group target
  add_custom_target(${dialect_target}_AllIncGen)
  # Main Dialect definition
  heir_dialect_tablegen(${dialect_name} Dialect dialect)
  # Ops
  heir_dialect_tablegen(${dialect_name} Ops op)
  # Types
  heir_dialect_tablegen(${dialect_name} Types typedef)
  # Type Interfaces
  heir_dialect_tablegen(${dialect_name} TypeInterfaces type-interface)
  # Attributes
  heir_dialect_tablegen(${dialect_name} Attributes attrdef)
  #Enums
  heir_dialect_tablegen(${dialect_name} Enums enum)
  #TODO (build): fix the dialect that puts Enums in the Attributes.td file!



  # Reset the directories to the original values
  set(CMAKE_CURRENT_BINARY_DIR ${original_current_binary_dir})
  set(CMAKE_CURRENT_SOURCE_DIR ${original_current_source_dir})

  #### C++ Library

  # Strip the namespace from the argument list, as it's not expected by add_mlir_dialect_library
  set(args ${ARGV})
  list(REMOVE_AT args 1)

  # Update the target name from ${dialect_name} to ${dialect_target}
  list(REMOVE_AT args 0)
  list(INSERT args 0 "${dialect_target}")

  # Create the main dialect library.
  # TODO (build): create custom macros instead of using the one from AddMLIR.cmake
  add_mlir_dialect_library(${args})

  # Ensure that the tablegen & copy targetrs are done before trying to build the dialect
  add_dependencies(${dialect_target} ${dialect_target}_AllIncGen ${dialect_target}_CopyHeaders)

  # Add the current directory to the include path, but with path relative to the project root dir
  target_include_directories(${dialect_target} PRIVATE ${custom_binary_dir_prefix})

endfunction() # add_heir_dialect


# custom TableGen helper for HEIR Dialects that follow our naming conventions
function(add_heir_dialect dialect dialect_namespace)
  add_custom_target(HEIR${dialect}IncGen)

  set(LLVM_TARGET_DEFINITIONS ${dialect}Dialect.td)
  mlir_tablegen(${dialect}Dialect.h.inc -gen-dialect-decls -dialect=${dialect_namespace})
  mlir_tablegen(${dialect}Dialect.cpp.inc -gen-dialect-defs -dialect=${dialect_namespace})
  add_public_tablegen_target(HEIR${dialect}DialectIncGen)
  add_dependencies(HEIR${dialect}IncGen HEIR${dialect}DialectIncGen)

  # Ops
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Ops.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect}Ops.td)
    mlir_tablegen(${dialect}Ops.h.inc -gen-op-decls -dialect=${dialect_namespace})
    mlir_tablegen(${dialect}Ops.cpp.inc -gen-op-defs -dialect=${dialect_namespace})
    add_public_tablegen_target(HEIR${dialect}OpsIncGen)
    add_dependencies(HEIR${dialect}IncGen HEIR${dialect}OpsIncGen)
  endif()

  # Types
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Types.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect}Types.td)
    mlir_tablegen(${dialect}Types.h.inc -gen-typedef-decls -dialect=${dialect_namespace})
    mlir_tablegen(${dialect}Types.cpp.inc -gen-typedef-defs -dialect=${dialect_namespace})
    add_public_tablegen_target(HEIR${dialect}TypesIncGen)
    add_dependencies(HEIR${dialect}IncGen HEIR${dialect}TypesIncGen)
  endif()

  # Attributes
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Attributes.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect}Attributes.td)
    mlir_tablegen(${dialect}Attributes.h.inc -gen-attrdef-decls -attrdefs-dialect=${dialect_namespace})
    mlir_tablegen(${dialect}Attributes.cpp.inc -gen-attrdef-defs -attrdefs-dialect=${dialect_namespace})
    add_public_tablegen_target(HEIR${dialect}AttributesIncGen)
    add_dependencies(HEIR${dialect}IncGen HEIR${dialect}AttributesIncGen)
  endif()

  #Enums
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Enums.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect}Enums.td)
    mlir_tablegen(${dialect}Enums.h.inc -gen-enum-decls)
    mlir_tablegen(${dialect}Enums.cpp.inc -gen-enum-defs)
    add_public_tablegen_target(HEIR${dialect}EnumsIncGen)
    add_dependencies(HEIR${dialect}IncGen HEIR${dialect}EnumsIncGen)
  #Enums (but from Attributes file)
  elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Attributes.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect}Attributes.td)
    mlir_tablegen(${dialect}Enums.h.inc -gen-enum-decls)
    mlir_tablegen(${dialect}Enums.cpp.inc -gen-enum-defs)
    add_public_tablegen_target(HEIR${dialect}EnumsIncGen)
    add_dependencies(HEIR${dialect}IncGen HEIR${dialect}EnumsIncGen)
  endif()

  # Type Interfaces
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect}TypeInterfaces.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect}TypeInterfaces.td)
    mlir_tablegen(${dialect}TypeInterfaces.h.inc -gen-type-interface-decls -name ${dialect_namespace})
    mlir_tablegen(${dialect}TypeInterfaces.cpp.inc -gen-type-interface-defs -name ${dialect_namespace})
    add_public_tablegen_target(HEIR${dialect}TypeInterfacesIncGen)
    add_dependencies(HEIR${dialect}IncGen HEIR${dialect}TypeInterfacesIncGen)
  endif()

endfunction() # add_heir_dialect


# custom TableGen helper for HEIR passes
# call add_heir_pass(someName) for normal use
# call add_heir_pass(someName PATTERNS) to generate rewriter patterns
function(add_heir_pass pass)
  set(LLVM_TARGET_DEFINITIONS ${pass}.td)
  mlir_tablegen(${pass}.h.inc -gen-pass-decls -name ${pass})

  if(ARGN MATCHES "PATTERNS")
    mlir_tablegen(${pass}.cpp.inc -gen-rewriters)
  endif()

  add_public_tablegen_target(HEIR${pass}IncGen)
endfunction() # add_heir_pass


## TODO: INTEGRATE THIS
# target_compile_features(my_lib PUBLIC cxx_std_17)
# if(CMAKE_CXX_STANDARD LESS 17)
#   message(FATAL_ERROR
#       "my_lib_project requires CMAKE_CXX_STANDARD >= 17 (got: ${CMAKE_CXX_STANDARD})")
# endif()

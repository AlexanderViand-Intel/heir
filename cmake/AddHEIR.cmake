include_guard()

# Make MLIR/LLVM CMake helper functions available
list(APPEND CMAKE_MODULE_PATH "${MLIR_CMAKE_DIR}")
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddMLIR)
include(AddLLVM)
include(TableGen)

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

  # Name of the dialect target (will be created later)
  set(dialect_target "heir__Dialect__${dialect_name}")

  # if we're not doing an in-source build
  # (i.e., the source and build directories are different),
  # Create all tablegen in a target-specific build directory
  set(original_current_binary_dir ${CMAKE_CURRENT_BINARY_DIR})
  set(original_currrent_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
  if(NOT ${CMAKE_CURRENT_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_BINARY_DIR})
    # get the relative path from the source directory to the current directory
    file(RELATIVE_PATH cur_src_dir_rel ${CMAKE_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR})
    # create a target-specific build directory at CMAKE_BINARY_DIR/TARGET/cur_src_dir_rel
    set(custom_bianry_dir_prefix ${CMAKE_BINARY_DIR}/target_include/${dialect_target})
    set(custom_binary_dir ${custom_bianry_dir_prefix}/${cur_src_dir_rel})
    set(CMAKE_CURRENT_BINARY_DIR ${custom_binary_dir})
    set(CMAKE_CURRENT_SOURCE_DIR ${custom_binary_dir})
    message(STATUS "Creating custom binary directory for ${dialect_target} at ${custom_binary_dir}")
  endif()

  # Copy Headers/etc to ${custom_binary_dir}
  # Yes, globbing is bad, but we're doing this just for
  # Ninja's overly picky dependency graph tracking,
  # i.e., to define the "BYPRODUCTS" of the custom target
  file(GLOB dialect_files LIST_DIRECTORIES false RELATIVE ${original_currrent_source_dir} ${original_currrent_source_dir}/*)
  list(TRANSFORM dialect_files PREPEND ${custom_binary_dir}/)
  add_custom_target(${dialect_target}_CopyHeaders
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${original_currrent_source_dir} ${custom_binary_dir}/
    BYPRODUCTS ${dialect_files}
    COMMENT "Copying ${dialect} files from ${original_currrent_source_dir} to ${custom_binary_dir}"
  )

  # TableGen target
  add_custom_target(${dialect_target}_AllIncGen)

  # Main Dialect definition
  set(LLVM_TARGET_DEFINITIONS ${dialect_name}Dialect.td)
  mlir_tablegen(${dialect_name}Dialect.h.inc -gen-dialect-decls -dialect=${dialect_namespace})
  mlir_tablegen(${dialect_name}Dialect.cpp.inc -gen-dialect-defs -dialect=${dialect_namespace})
  add_public_tablegen_target(${dialect_target}_DialectIncGen)
  add_dependencies(${dialect_target}_DialectIncGen ${dialect_target}_CopyHeaders)
  add_dependencies(${dialect_target}_AllIncGen ${dialect_target}_DialectIncGen)

  # Ops
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect_name}Ops.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}Ops.td)
    mlir_tablegen(${dialect_name}Ops.h.inc -gen-op-decls -dialect=${dialect_namespace})
    mlir_tablegen(${dialect_name}Ops.cpp.inc -gen-op-defs -dialect=${dialect_namespace})
    add_public_tablegen_target(${dialect_target}_OpsIncGen)
    add_dependencies(${dialect_target}_OpsIncGen ${dialect_target}_CopyHeaders)
    add_dependencies(${dialect_target}_AllIncGen ${dialect_target}_OpsIncGen)
  endif()

  # Types
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect_name}Types.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}Types.td)
    mlir_tablegen(${dialect_name}Types.h.inc -gen-typedef-decls -dialect=${dialect_namespace})
    mlir_tablegen(${dialect_name}Types.cpp.inc -gen-typedef-defs -dialect=${dialect_namespace})
    add_public_tablegen_target(${dialect_target}_TypesIncGen)
    add_dependencies(${dialect_target}_TypesIncGen ${dialect_target}_CopyHeaders)
    add_dependencies(${dialect_target}_AllIncGen ${dialect_target}_TypesIncGen)
  endif()

  # Attributes
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect_name}Attributes.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}Attributes.td)
    mlir_tablegen(${dialect_name}Attributes.h.inc -gen-attrdef-decls -attrdefs-dialect=${dialect_namespace})
    mlir_tablegen(${dialect_name}Attributes.cpp.inc -gen-attrdef-defs -attrdefs-dialect=${dialect_namespace})
    add_public_tablegen_target(${dialect_target}_AttributesIncGen)
    add_dependencies(${dialect_target}_AttributesIncGen ${dialect_target}_CopyHeaders)
    add_dependencies(${dialect_target}_AllIncGen ${dialect_target}_AttributesIncGen)
  endif()

  #Enums
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect_name}Enums.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}Enums.td)
    mlir_tablegen(${dialect_name}Enums.h.inc -gen-enum-decls)
    mlir_tablegen(${dialect_name}Enums.cpp.inc -gen-enum-defs)
    add_public_tablegen_target(${dialect_target}_EnumsIncGen)
    add_dependencies(${dialect_target}_EnumsIncGen ${dialect_target}_CopyHeaders)
    add_dependencies(${dialect_target}_AllIncGen ${dialect_target}_EnumsIncGen)
  #Enums (but from Attributes file) #TODO (build): Deprecate this pattern
  elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect_name}Attributes.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}Attributes.td)
    mlir_tablegen(${dialect_name}Enums.h.inc -gen-enum-decls)
    mlir_tablegen(${dialect_name}Enums.cpp.inc -gen-enum-defs)
    add_public_tablegen_target(${dialect_target}_EnumsIncGen)
    add_dependencies(${dialect_target}_EnumsIncGen ${dialect_target}_CopyHeaders)
    add_dependencies(${dialect_target}_AllIncGen ${dialect_target}_EnumsIncGen)
  endif()

  # Type Interfaces
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect_name}TypeInterfaces.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}TypeInterfaces.td)
    mlir_tablegen(${dialect_name}TypeInterfaces.h.inc -gen-type-interface-decls -name ${dialect_namespace})
    mlir_tablegen(${dialect_name}TypeInterfaces.cpp.inc -gen-type-interface-defs -name ${dialect_namespace})
    add_public_tablegen_target(${dialect_target}_TypeInterfacesIncGen)
    add_dependencies(${dialect_target}_TypeInterfacesIncGen ${dialect_target}_CopyHeaders)
    add_dependencies(${dialect_target}_AllIncGen ${dialect_target}_TypeInterfacesIncGen)
  endif()

  # Reset the directories to the original values
  set(CMAKE_CURRENT_BINARY_DIR ${original_current_binary_dir})
  set(CMAKE_CURRENT_SOURCE_DIR ${original_currrent_source_dir})

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

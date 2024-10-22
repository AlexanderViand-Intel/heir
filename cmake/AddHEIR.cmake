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
# And adds the new tablegen target as a dependency of the dialect target ABC
macro(heir_dialect_tablegen dialect_name file_suffix cmd)
  if(EXISTS "${original_current_source_dir}/${dialect_name}${file_suffix}.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}${file_suffix}.td)
    set(space " ")
    mlir_tablegen(${dialect_name}${file_suffix}.h.inc
                  -gen-${cmd}-decls
                  #-dialect=${dialect_namespace}
                  DEPENDS
                  ${dialect_target}_TablegenDeps
                  EXTRA_INCLUDES
                  # get the INCLUDE_DIRECTORIES property of ${dialect_target}_AllIncGen
                  # which is where we put all the tablegen include directories
                  # the following line is also an incredibly dirty hack because llvm's CMake
                  # setup treats the entire thing as a single include directory, but thankfully
                  # we can make the actual tablegen command happy by just adding our own -I separators
                  $<JOIN:$<TARGET_PROPERTY:${dialect_target}_AllIncGen,INTERFACE_INCLUDE_DIRECTORIES>,\\\ -I>
                  )
    mlir_tablegen(${dialect_name}${file_suffix}.cpp.inc
                   -gen-${cmd}-defs
                   # -dialect=${dialect_namespace}
                  DEPENDS
                  ${dialect_target}_TablegenDeps
                  EXTRA_INCLUDES
                  $<JOIN:$<TARGET_PROPERTY:${dialect_target}_AllIncGen,INTERFACE_INCLUDE_DIRECTORIES>,\\\ -I>
                  )
    # Create target and set up dependencies on (a) the copy operation and (b) tablegen dependencies
    add_public_tablegen_target(${dialect_target}_${file_suffix}IncGen)
    add_dependencies(${dialect_target}_${file_suffix}IncGen ${dialect_target}_CopyHeaders)
    add_dependencies(${dialect_target}_${file_suffix}IncGen ${dialect_target}_TablegenDeps)
    # Add the newly created target to the convenience target ${dialect_target}_AllIncGen
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
# This function looks for ${dialect_name}<sufffix>.td files in the current source directory
# (where <suffix> is one of Dialect, Ops, Types, TypeInterfaces, Attributes, Enums)
# and will perform the associated tablegen operations should the file exists.
# It will call them with -name=${dialect_namespace} and -attrdefs-dialect=${dialect_namespace}
#
# For an out-of-source build (usual case), it will create a target-specific binary directory
# where it will make the (existing and generated) headers associated with the dialect available.
# This helps achieve better dependency tracking, similar to how Bazel handles this process.
# Note that this only works for HEIR's own dependencies on other HEIR components,
# and not for dependencies on LLVM/MLIR, as the upstream project does not follow this approach.
function(add_heir_dialect dialect_name dialect_namespace)
  message(CHECK_START "Configuring HEIR Dialect ${dialect_name}")
  list(APPEND CMAKE_MESSAGE_INDENT " -- ")

  # Name of the dialect target (actual target will be created later)
  set(dialect_target "heir__Dialect__${dialect_name}")

  # Bazel-style copying of sources to a new target-specific binary directory
  # if we're not doing an in-source build
  # (i.e., the source and build directories are different),
  # We do everything in a target-specific build directory
  set(original_current_binary_dir ${CMAKE_CURRENT_BINARY_DIR})
  set(original_current_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
  if(NOT ${CMAKE_CURRENT_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_BINARY_DIR})
    # get the relative path from the source directory to the current directory
    file(RELATIVE_PATH cur_src_dir_rel ${CMAKE_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR})
    # create a target-specific build directory at CMAKE_BINARY_DIR/TARGET/cur_src_dir_rel
    set(binary_dir_prefix ${CMAKE_BINARY_DIR}/target_include/${dialect_target})
    set(custom_binary_dir ${binary_dir_prefix}/${cur_src_dir_rel})
    message(STATUS "Creating custom binary directory for ${dialect_target} at ${custom_binary_dir}")

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

    # Overwrite the standard cmake variables (will be reset at end of function)
    set(CMAKE_CURRENT_BINARY_DIR ${custom_binary_dir})
    set(CMAKE_CURRENT_SOURCE_DIR ${custom_binary_dir})
  else()
    # used below the if, so must always be defined
    set(binary_dir_prefix ${CMAKE_BINARY_DIR})
    add_custom_target(${dialect_target}_CopyHeaders) #no-op target to depend on
  endif()

  # Grab the list of dependencies passed in and grab all their include directories
  # (taken from add_mlir_library in MLIR's AddMLIR.cmake)
  cmake_parse_arguments(ARG
  "SHARED;INSTALL_WITH_TOOLCHAIN;EXCLUDE_FROM_LIBMLIR;DISABLE_INSTALL;ENABLE_AGGREGATION;OBJECT"
  ""
  "ADDITIONAL_HEADERS;DEPENDS;LINK_COMPONENTS;LINK_LIBS"
  ${ARGN})

  # Includes are the current binary directory and the include directories of all dependencies
  # However, we will only be able to get the include directories of the dependencies
  # after the dependencies have been created, so it needs to be evaluated AFTER configuration
  # i.e., during the generation step -> generator expression stuff
  set(dialect_tablegen_include_dirs_GENEXP_helper  "")
  foreach(dep ${ARG_LINK_LIBS} ${ARG_LINK_COMPONENTS})
    #FIXME: if a target already ends in _AllIncGen, we should not append that string again!
    set(_prop "$<TARGET_PROPERTY:${dep},INCLUDE_DIRECTORIES>")
    set(_tgt "$<TARGET_EXISTS:${dep}_AllIncGen>")
    list(APPEND dialect_tablegen_include_dirs_GENEXP_helper  "$<${_tgt}:${_prop}>")
  endforeach()
  set(dialect_tablegen_include_dirs_GENEXP "$<FILTER:${dialect_tablegen_include_dirs_GENEXP_helper},EXCLUDE,^$>")
  message(STATUS "Dialect ${dialect_name} include dirs: ${dialect_tablegen_include_dirs_GENEXP}")
  add_library(${dialect_target}_AllIncGen INTERFACE)
  target_include_directories(${dialect_target}_AllIncGen INTERFACE ${binary_dir_prefix} ${dialect_tablegen_include_dirs_GENEXP})
  # # get INCLUDE_DIRECTORIES property of ${dialect_target}_AllIncGen
  # get_target_property(dummy ${dialect_target}_AllIncGen INTERFACE_INCLUDE_DIRECTORIES)
  # message(STATUS "Dialect ${dialect_name} include dirs:" ${dummy})
  file(GENERATE OUTPUT ${dialect_target}_AllIncGen_DEBUG CONTENT "$<JOIN:$<TARGET_PROPERTY:${dialect_target}_AllIncGen,INTERFACE_INCLUDE_DIRECTORIES>, -I>")
  set(dialect_tablegen_dependencies_GENEXP "")
  foreach(dep ${ARG_DEPENDS} ${ARG_LINK_LIBS} ${ARG_LINK_COMPONENTS})
    #FIXME: if a target already ends in _AllIncGen, we should not append that string again!
    list(APPEND dialect_tablegen_dependencies_GENEXP  $<TARGET_NAME_IF_EXISTS:${dep}_AllIncGen>)
  endforeach()
 # add_custom_target(${dialect_target}_dialect_tablegen_dependencies_GENEXP_DEBUG COMMAND ${CMAKE_COMMAND} -E echo ${dialect_tablegen_dependencies_GENEXP})
  add_custom_target(${dialect_target}_TablegenDeps
                    DEPENDS ${dialect_tablegen_dependencies_GENEXP}
                    )
  # Strip the namespace from the argument list, as it's not expected by add_mlir_dialect_library
  set(args ${ARGV})
  list(REMOVE_AT args 1)

  # Update the target name from ${dialect_name} to ${dialect_target}
  list(REMOVE_AT args 0)
  list(INSERT args 0 "${dialect_target}")

  # Create the main dialect library.
  # While it's generally a really bad idea to try and "forward" arguments to a CMake macro
  # (bad things happen to lists, see https://gitlab.kitware.com/cmake/cmake/-/issues/22157),
  # the MLIR/LLVM macros already do this internally quite a bit so it should be safe to do
  # unless something changes with the macros in AddMLIR.cmake / AddLLVM.cmake upstream
  add_mlir_dialect_library(${args})

  # Add it's own directory to the include directories
  target_include_directories(${dialect_target} PUBLIC ${binary_dir_prefix})
  # # Add includes for dependencies
  target_include_directories(${dialect_target} PUBLIC ${dialect_tablegen_include_dirs_GENEXP})

  # target_include_directories(${dialect_target} PUBLIC ${dialect_tablegen_include_dirs_GENEXP})

  # Create each tablegen target, depending on the existence of the corresponding .td file
  # FIXME: The macro needs to handle tablegen dependencies on other HEIR dialects
  # add_library(${dialect_target}_AllIncGen INTERFACE) # moved up for testing stuff
  set(target_to_use ${dialect_target})
  if(TARGET obj.${dialect_target})
    # MLIR/LLVM might decide to also create this obj. target
    # since the main target depends on it, we can add our dependency only there
    # as this will create slightly nicer dependency graphs while debugging this stuff
    # FIXME: go back to setting dependencies on both targets
    set(target_to_use obj.${dialect_target})
  endif()
  add_dependencies(${target_to_use} ${dialect_target}_AllIncGen)

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

  # Reset the directories to the original values
  set(CMAKE_CURRENT_BINARY_DIR ${original_current_binary_dir})
  set(CMAKE_CURRENT_SOURCE_DIR ${original_current_source_dir})

  # Signal success if we made it this far
  list(POP_BACK CMAKE_MESSAGE_INDENT)
  message(CHECK_PASS "completed")

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


## TODO: INTEGRATE THIS?
# target_compile_features(my_lib PUBLIC cxx_std_17)
# if(CMAKE_CXX_STANDARD LESS 17)
#   message(FATAL_ERROR
#       "my_lib_project requires CMAKE_CXX_STANDARD >= 17 (got: ${CMAKE_CXX_STANDARD})")
# endif()

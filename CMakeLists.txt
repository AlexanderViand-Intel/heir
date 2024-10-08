cmake_minimum_required(VERSION 3.18)

project(HEIR LANGUAGES CXX C)

# Custom CMake Setup (if required)
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/modules")

# TODO: set this on target level, not project!
# set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard to conform to")

# if no build type was specified, default to release
if (NOT CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE STREQUAL "")
  set(CMAKE_BUILD_TYPE "Release")
endif()

# If MLIR_DIR is set
find_package(MLIR CONFIG)
if (NOT MLIR_FOUND)
  message(STATUS "MLIR not found. Building MLIR from source.")

  # Extract the LLVM commit ID from bazel/import_llvm.bzl
  file(READ "${CMAKE_SOURCE_DIR}/bazel/import_llvm.bzl" BAZEL_FILE_CONTENT)
  string(REGEX MATCH "LLVM_COMMIT = \"([a-f0-9]+)\"" _ ${BAZEL_FILE_CONTENT})
  set(LLVM_COMMIT_ID ${CMAKE_MATCH_1})
  message(STATUS "LLVM commit ID: ${LLVM_COMMIT_ID}")

  # FetchContent setup for LLVM/MLIR
  include(FetchContent)
  Set(FETCHCONTENT_QUIET FALSE)
  FetchContent_Declare(
      llvm-project
      GIT_REPOSITORY https://github.com/llvm/llvm-project.git
      GIT_TAG ${LLVM_COMMIT_ID}
      GIT_PROGRESS TRUE
      # We do not want FetchContent to actually add this as a subdirectory
      # so we provide a non-existing CMakeLists.txt location, as FetchContent
      # only calls add_subdirectory if it finds a CMakeLists.txt file.
      # Since llvm-project does not currently have a top-level CMakeLists.txt
      # we could also omit this entirely, but that might break if one is added in the future
      SOURCE_SUBDIR NonExistentSubdirToPreventAddSubDirectoryCall
  )

  # Set Options for LLVM/MLIR here
  set(LLVM_ENABLE_PROJECTS "mlir")
  set(LLVM_TARGETS_TO_BUILD "Native") # only build for current host

  # Download LLVM/MLIR only
  FetchContent_MakeAvailable(llvm-project)

  # TODO: Similar to IREE, manually set up the variables usually set by find_package(MLIR)
  # See https://github.com/iree-org/iree/blob/main/build_tools/cmake/iree_llvm.cmake
endif()

message(STATUS "Using MLIRConfig.cmake in: ${MLIR_DIR}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

# HEIR prefixes all MLIR and LLVM includes with their full path, i.e.,
# "mlir/include/<normal include path>" and "llvm/include/<normal include path>"
# because of a Google internal file system requirement, so we need to add these.
# Note that we might still need the original include paths for MLIR/LLVM headers.
foreach(inc_dir IN LISTS MLIR_INCLUDE_DIRS)
  if("${inc_dir}" MATCHES "mlir[/\\]include$")
    get_filename_component(parent_dir "${inc_dir}" DIRECTORY)
    get_filename_component(grandparent_dir "${parent_dir}" DIRECTORY)
    list(APPEND MLIR_INCLUDE_DIRS "${grandparent_dir}")
  endif()
endforeach()

# same for LLVM
foreach(inc_dir IN LISTS LLVM_INCLUDE_DIRS)
  if("${inc_dir}" MATCHES "llvm[/\\]include$")
    get_filename_component(parent_dir "${inc_dir}" DIRECTORY)
    get_filename_component(grandparent_dir "${parent_dir}" DIRECTORY)
    list(APPEND LLVM_INCLUDE_DIRS "${grandparent_dir}")
  endif()
endforeach()

# print all include directories
message(STATUS "MLIR include dirs: ${MLIR_INCLUDE_DIRS}")
message(STATUS "LLVM include dirs: ${LLVM_INCLUDE_DIRS}")

# get convenience lists defined by MLIRConfig.cmake
get_property(MLIR_DIALECT_LIBS GLOBAL PROPERTY MLIR_DIALECT_LIBS)
get_property(MLIR_CONVERSION_LIBS GLOBAL PROPERTY MLIR_CONVERSION_LIBS)
get_property(MLIR_EXTENSION_LIBS GLOBAL PROPERTY MLIR_EXTENSION_LIBS)
get_property(MLIR_TRANSFORMS_LIBS GLOBAL PROPERTY MLIR_TRANSFORMS_LIBS)
get_property(MLIR_TRANSLATION_LIBS GLOBAL PROPERTY MLIR_TRANSLATION_LIBS)
get_property(MLIR_UPSTREAM_CAPI_LIBS GLOBAL PROPERTY MLIR_UPSTREAM_CAPI_LIBS)

option(ENABLE_YOSYS "Enable YOSYS for yosys-optimizer pass (optional)" FALSE)

if(ENABLE_YOSYS)
   message("Yosys enabled! Make sure ABC and Yosys development files and libraries are on the path")
else()
   add_compile_options(-DHEIR_NO_YOSYS=1)
endif()

# add_subdirectory(lib)
add_subdirectory(tools)
# add_subdirectory(tests)

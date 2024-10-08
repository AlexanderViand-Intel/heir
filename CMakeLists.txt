cmake_minimum_required(VERSION 3.18)

if(POLICY CMP0116)
  cmake_policy(SET CMP0116 OLD)
endif()

project(HEIR LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard to conform to")

# if no build type was specified, default to release
if (NOT CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE STREQUAL "")
  set(CMAKE_BUILD_TYPE "Release")
endif()

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

option(ENABLE_YOSYS "Enable YOSYS for yosys-optimizer pass (optional)" FALSE)

if(ENABLE_YOSYS)
   message("Yosys enabled! Make sure ABC and Yosys development files and libraries are on the path")
else()
   add_compile_options(-DHEIR_NO_YOSYS=1)
endif()

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/modules")
set(HEIRLIBDIR ${CMAKE_CURRENT_SOURCE_DIR})
# add_subdirectory(lib)
# add_subdirectory(tools)
# add_subdirectory(tests)

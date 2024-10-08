
# toy-opt is a simple command line tool that only depends on the MLIR/LLVM  libraries
add_executable(toy-opt toy-opt.cpp)
# add MLIR and LLVM include directories
target_include_directories(toy-opt PRIVATE ${MLIR_INCLUDE_DIRS})
target_include_directories(toy-opt PRIVATE ${LLVM_INCLUDE_DIRS})
# link against MLIR and LLVM libraries

# set the C++ standard to 17
target_compile_features(toy-opt PRIVATE cxx_std_17)

# print all include directories
message(STATUS "MLIR include directories: ${MLIR_INCLUDE_DIRS}")

# print all variables that start with LLVM
get_cmake_property(_variableNames VARIABLES)
foreach (_variableName ${_variableNames})
    if (_variableName MATCHES "^LLVM")
        message(STATUS "${_variableName}=${${_variableName}}")
    endif()
endforeach()

# Print all variables that start with MLIR from all scopes

# Global scope
get_cmake_property(_variableNames VARIABLES)
foreach (_variableName ${_variableNames})
    if (_variableName MATCHES "^MLIR")
        message(STATUS "Global: ${_variableName}=${${_variableName}}")
    endif()
endforeach()

# Directory scope
get_directory_property(_dirVars DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} VARIABLES)
foreach (_variableName ${_dirVars})
    if (_variableName MATCHES "^MLIR")
        message(STATUS "Directory: ${_variableName}=${${_variableName}}")
    endif()
endforeach()

# Target scope
get_property(_targets GLOBAL PROPERTY TARGETS)
foreach (_target ${_targets})
    get_target_property(_targetVars ${_target} VARIABLES)
    foreach (_variableName ${_targetVars})
        if (_variableName MATCHES "^MLIR")
            message(STATUS "Target ${_target}: ${_variableName}=${${_variableName}}")
        endif()
    endforeach()
endforeach()

# Source file scope
get_property(_sourceFiles DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY SOURCE_FILES)
foreach (_sourceFile ${_sourceFiles})
    get_source_file_property(_sourceVars ${_sourceFile} VARIABLES)
    foreach (_variableName ${_sourceVars})
        if (_variableName MATCHES "^MLIR")
            message(STATUS "Source file ${_sourceFile}: ${_variableName}=${${_variableName}}")
        endif()
    endforeach()
endforeach()


# toy-opt is a simple command line tool that only depends on the MLIR/LLVM  libraries
add_executable(toy-opt toy-opt.cpp)

# add MLIR and LLVM include directories
target_include_directories(toy-opt PRIVATE ${MLIR_INCLUDE_DIRS})
target_include_directories(toy-opt PRIVATE ${LLVM_INCLUDE_DIRS})

# core MLIR IR things, including DialectRegistry
target_link_libraries(toy-opt PRIVATE MLIRIR)

# MlirOptMain helper to register command-line options
target_link_libraries(toy-opt PRIVATE MLIRMlirOptMain)

#  link all dialect libs for registerAllDialects()
target_link_libraries(toy-opt PRIVATE ${MLIR_DIALECT_LIBS})

# link all extension libs for registerAllExtensions()
target_link_libraries(toy-opt PRIVATE ${MLIR_EXTENSION_LIBS})

# link all conversion and transform libs for registerAllPasses()
target_link_libraries(toy-opt PRIVATE ${MLIR_CONVERSION_LIBS})
target_link_libraries(toy-opt PRIVATE ${MLIR_TRANSFORMS_LIBS})

# set the C++ standard to 17
target_compile_features(toy-opt PRIVATE cxx_std_17)

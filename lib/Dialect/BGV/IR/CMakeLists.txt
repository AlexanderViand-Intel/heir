add_heir_dialect(BGV bgv)

add_mlir_dialect_library(HEIRBGV
    BGVDialect.cpp

    DEPENDS
    HEIRBGVIncGen

    LINK_LIBS PUBLIC
    HEIR__Dialect__LWE

    # MLIR/LLVM Features
    LLVMSupport
    MLIRDialect
    MLIRInferTypeOpInterface
    MLIRIR
    MLIRSupport
)

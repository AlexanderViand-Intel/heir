add_heir_dialect(BGV bgv
    BGVDialect.cpp

    LINK_LIBS PUBLIC
    HEIR__Dialect__LWE

    # MLIR/LLVM Features
    LLVMSupport
    MLIRDialect
    MLIRInferTypeOpInterface
    MLIRIR
    MLIRSupport
)

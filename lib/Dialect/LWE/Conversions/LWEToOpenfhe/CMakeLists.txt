add_mlir_conversion_library(HEIRLWEToOpenfhe
    LWEToOpenfhe.cpp

    LINK_LIBS PUBLIC
    HEIRConversionUtils
    HEIR__Dialect__LWE
    HEIR__Dialect__LWE
    HEIROpenfhe

    MLIRIR
    MLIRPass
    MLIRInferTypeOpInterface
    MLIRArithDialect
    MLIRFuncDialect
    LLVMSupport
    MLIRSupport
    MLIRDialect
    MLIRTransformUtils
    MLIRIR
)

add_mlir_conversion_library(HEIRLWEToOpenfhe
    LWEToOpenfhe.cpp

    LINK_LIBS PUBLIC
    HEIRConversionUtils
    heir__Dialect__LWE
    heir__Dialect__LWE
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

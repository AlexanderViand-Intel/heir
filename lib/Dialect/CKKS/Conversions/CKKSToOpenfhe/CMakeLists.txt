add_heir_pass(CKKSToOpenfhe)

add_mlir_conversion_library(HEIRCKKSToOpenfhe
    CKKSToOpenfhe.cpp

    DEPENDS
    HEIRCKKSToOpenfheIncGen

    LINK_LIBS PUBLIC
    HEIRConversionUtils
    HEIRCKKS
    heir__Dialect__LWE
    HEIROpenfhe
    HEIRLWEToOpenfhe
    HEIRRlweToOpenfhe

    MLIRIR
    MLIRPass
    MLIRInferTypeOpInterface
    MLIRArithDialect
    MLIRFuncDialect
    LLVMSupport
    MLIRSupport
    MLIRDialect
    MLIRTransformUtils
    MLIRTensorDialect
)

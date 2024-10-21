add_heir_pass(BGVToOpenfhe)

add_mlir_conversion_library(HEIRBGVToOpenfhe
    BGVToOpenfhe.cpp

    DEPENDS
    HEIRBGVToOpenfheIncGen

    LINK_LIBS PUBLIC
    HEIRBGV
    HEIR__Dialect__LWE
    HEIROpenfhe
    HEIRConversionUtils
    LLVMSupport
    MLIRArithDialect
    MLIRDialect
    MLIRFuncDialect
    MLIRInferTypeOpInterface
    MLIRIR
    MLIRPass
    MLIRSupport
    MLIRTransformUtils
)

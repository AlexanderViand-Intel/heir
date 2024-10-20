add_heir_pass(SecretToBGV)

add_mlir_conversion_library(HEIRSecretToBGV
    SecretToBGV.cpp

    DEPENDS
    HEIRSecretToBGVIncGen

    LINK_LIBS PUBLIC
    HEIRConversionUtils

    HEIRBGV
    heir__Dialect__LWE
    HEIRSecret
    HEIRTensorExt
    LLVMSupport

    MLIRArithDialect
    MLIRIR
    MLIRPass
    MLIRPolynomialDialect
    MLIRSupport
    MLIRTensorDialect
    MLIRTransformUtils
)

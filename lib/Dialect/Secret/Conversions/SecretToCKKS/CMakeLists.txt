add_heir_pass(SecretToCKKS)

add_mlir_conversion_library(HEIRSecretToCKKS
    SecretToCKKS.cpp

    DEPENDS
    HEIRSecretToCKKSIncGen

    LINK_LIBS PUBLIC
    HEIRConversionUtils

    HEIRCKKS
    HEIR__Dialect__LWE
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

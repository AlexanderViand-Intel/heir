add_heir_pass(BGVToLWE)

add_mlir_conversion_library(HEIRBGVToLWE
    BGVToLWE.cpp

    DEPENDS
    HEIRBGVToLWEIncGen

    LINK_LIBS PUBLIC
    HEIRConversionUtils
    HEIRBGV
    heir__Dialect__LWE
    MLIRPolynomialDialect
    MLIRArithDialect
    MLIRTensorDialect

    MLIRTransformUtils

    MLIRIR
    MLIRPass
    MLIRSupport
    MLIRDialect
)

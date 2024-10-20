add_heir_pass(SecretToCGGI)

add_mlir_dialect_library(HEIRSecretToCGGI
    SecretToCGGI.cpp

    DEPENDS
    HEIRSecretToCGGIIncGen

    LINK_LIBS PUBLIC

    HEIRConversionUtils
    HEIRCGGI
    HEIRComb
    heir__Dialect__LWE
    HEIRSecret

    LLVMSupport
    MLIRAffineDialect
    MLIRAffineUtils
    MLIRArithDialect
    MLIRDialectUtils
    MLIRIR
    MLIRMemRefDialect
    MLIRPass
    MLIRSupport
    MLIRTransformUtils
)

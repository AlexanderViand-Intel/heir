add_heir_pass(CombToCGGI)

add_mlir_conversion_library(HEIRCombToCGGI
    CombToCGGI.cpp

    DEPENDS
    HEIRCombToCGGIIncGen

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

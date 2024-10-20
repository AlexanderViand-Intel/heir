add_heir_pass(CGGIToJaxite)

add_mlir_conversion_library(HEIRCGGIToJaxite
    CGGIToJaxite.cpp

    DEPENDS
    HEIRCGGIToJaxiteIncGen
    HEIRCGGI
    HEIRJaxite
    heir__Dialect__LWE
    HEIRConversionUtils

    LINK_LIBS PUBLIC
    HEIRCGGI
    HEIRJaxite
    heir__Dialect__LWE
    HEIRConversionUtils

    LLVMSupport
    MLIRArithDialect
    MLIRFuncDialect
    MLIRIR
    MLIRMemRefDialect
    MLIRPass
    MLIRSupport
    MLIRTensorDialect
    MLIRTransformUtils
)

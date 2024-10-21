add_mlir_conversion_library(HEIRRlweToOpenfhe
    RlweToOpenfhe.cpp

    LINK_LIBS PUBLIC
        MLIRIR
        MLIRSupport
        MLIRSupport
        MLIRTransformUtils
        HEIRConversionUtils
        HEIR__Dialect__LWE
        HEIROpenfhe
        MLIRArithDialect
        MLIRFuncDialect
        MLIRIR
)

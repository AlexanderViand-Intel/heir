add_mlir_library(HEIRJaxiteEmitter
    JaxiteEmitter.cpp

    LINK_LIBS PUBLIC
    HEIRSelectVariableNames
    HEIRJaxite
    heir__Dialect__LWE
    HEIRTargetUtils
    LLVMSupport
    MLIRArithDialect
    MLIRAffineDialect
    MLIRFuncDialect
    MLIRIR
    MLIRMemRefDialect
    MLIRSupport
    MLIRTensorDialect
    MLIRTranslateLib
)
target_link_libraries(HEIRTarget INTERFACE HEIRJaxiteEmitter)

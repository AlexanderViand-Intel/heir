add_heir_dialect(CGGI cggi)

add_mlir_dialect_library(HEIRCGGI
    CGGIDialect.cpp
    CGGIOps.cpp

    DEPENDS
    HEIRCGGIIncGen
    heir__Dialect__LWE
)

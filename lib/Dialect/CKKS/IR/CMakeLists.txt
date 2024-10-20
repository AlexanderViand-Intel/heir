add_heir_dialect(CKKS ckks)

add_mlir_dialect_library(HEIRCKKS
    CKKSDialect.cpp

    DEPENDS
    HEIRCKKSIncGen
    HEIR__Dialect__LWE
)

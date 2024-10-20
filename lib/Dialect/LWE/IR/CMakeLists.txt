add_heir_dialect(LWE lwe
        LWEDialect.cpp

        DEPENDS
        # TODO (build): how to handle MLIR dependencies? Always link common ones in add_heir_dialect?
        MLIRInferTypeOpInterface
)

#ifndef LIB_DIALECT_BGV_CONVERSIONS_BGVTOLWE_BGVTOLWE_TD_
#define LIB_DIALECT_BGV_CONVERSIONS_BGVTOLWE_BGVTOLWE_TD_

include "mlir/Pass/PassBase.td"

def BGVToLWE : Pass<"bgv-to-lwe"> {
  let summary = "Lower `bgv` to `lwe` dialect.";

  let description = [{
    This pass lowers the `bgv` dialect to `lwe` dialect.
  }];

  let dependentDialects = [
    "mlir::heir::bgv::BGVDialect",
    "mlir::heir::lwe::LWEDialect",
    "mlir::tensor::TensorDialect",
  ];
}

#endif  // LIB_DIALECT_BGV_CONVERSIONS_BGVTOLWE_BGVTOLWE_TD_

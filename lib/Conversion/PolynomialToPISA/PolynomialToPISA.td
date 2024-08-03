#ifndef LIB_CONVERSION_POLYNOMIALTOPISA_POLYNOMIALTOPISA_TD_
#define LIB_CONVERSION_POLYNOMIALTOPISA_POLYNOMIALTOPISA_TD_

include "mlir/Pass/PassBase.td"

def PolynomialToPISA : Pass<"polynomial-to-pisa"> {
  let summary = "Lower `polynomial` to `pisa` dialect.";
  let dependentDialects = [
    "mlir::polynomial::PolynomialDialect",
    "mlir::heir::pisa::PISADialect",
  ];
}

#endif  // LIB_CONVERSION_POLYNOMIALTOPISA_POLYNOMIALTOPISA_TD_

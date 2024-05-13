#ifndef LIB_DIALECT_RNS_IR_RNSTRAITS_TD_
#define LIB_DIALECT_RNS_IR_RNSTRAITS_TD_

// Elementwise op can be applied to all-RNS operands (c.f. "Scalariable" in mlir/IR/OpBase.td)
def RNSizable : NativeOpTrait<"RNSizable", [Elementwise]> {
    let cppNamespace = "::mlir::heir::rns";
}

#endif // LIB_DIALECT_RNS_IR_RNSTRAITS_TD_

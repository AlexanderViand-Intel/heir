#ifndef LIB_DIALECT_PISA_IR_PISAOPS_TD_
#define LIB_DIALECT_PISA_IR_PISAOPS_TD_

include "lib/Dialect/PISA/IR/PISADialect.td"
include "mlir/IR/BuiltinAttributes.td"
include "mlir/IR/CommonTypeConstraints.td"
include "mlir/IR/OpBase.td"

class PISA_Op<string mnemonic, list<Trait> traits = []> :
        Op<PISA_Dialect, mnemonic, traits> {
  let cppNamespace = "::mlir::heir::pisa";
}

#endif  // LIB_DIALECT_PISA_IR_PISAOPS_TD_

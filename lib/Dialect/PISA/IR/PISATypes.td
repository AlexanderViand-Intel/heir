#ifndef LIB_DIALECT_PISA_IR_PISATYPES_TD_
#define LIB_DIALECT_PISA_IR_PISATYPES_TD_

include "lib/Dialect/PISA/IR/PISADialect.td"

include "lib/Dialect/PISA/IR/PISAAttributes.td"


include "mlir/IR/DialectBase.td"
include "mlir/IR/AttrTypeBase.td"

// A base class for all types in this dialect
class PISA_Type<string name, string typeMnemonic>
    : TypeDef<PISA_Dialect, name> {
  let mnemonic = typeMnemonic;
}


#endif  // LIB_DIALECT_PISA_IR_PISATYPES_TD_

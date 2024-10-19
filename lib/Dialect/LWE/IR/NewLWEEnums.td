include "mlir/IR/EnumAttr.td"

def LWE_EncryptionTypeEnum : I32EnumAttr<"LweEncryptionType", "An enum attribute representing an encryption method", [
  I32EnumAttrCase<"msb", 0>,
  I32EnumAttrCase<"lsb", 1>,
  I32EnumAttrCase<"mix", 2>
]> {
    let cppNamespace = "::mlir::heir::lwe";
}

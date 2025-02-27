#ifndef LIB_DIALECT_BGV_IR_BGVOPS_TD_
#define LIB_DIALECT_BGV_IR_BGVOPS_TD_

include "BGVDialect.td"

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/InferTypeOpInterface.td"

include "lib/Dialect/LWE/IR/LWETypes.td"
include "lib/Dialect/LWE/IR/LWETraits.td"
include "lib/Dialect/Polynomial/IR/PolynomialAttributes.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/IR/BuiltinAttributes.td"

class BGV_Op<string mnemonic, list<Trait> traits = []> :
        Op<BGV_Dialect, mnemonic, traits> {
  let cppNamespace = "::mlir::heir::bgv";
  let assemblyFormat = [{
    operands attr-dict `:`  functional-type(operands, results)
  }];
}

class BGV_CiphertextPlaintextOp<string mnemonic, list<Trait> traits =
    [Pure, AllTypesMatch<["ciphertextInput", "output"]>,
    TypesMatchWith<"type of 'plaintextInput' matches encoding type of 'ciphertextInput'",
                    "ciphertextInput", "plaintextInput",
                    "lwe::NewLWEPlaintextType::get($_ctxt, "
                      "::llvm::cast<lwe::NewLWECiphertextType>($_self).getApplicationData(),"
                      "::llvm::cast<lwe::NewLWECiphertextType>($_self).getPlaintextSpace())">]> :
        BGV_Op<mnemonic, traits> {
  let arguments = (ins
    NewLWECiphertext:$ciphertextInput,
    NewLWEPlaintext:$plaintextInput
  );

  let results = (outs
    NewLWECiphertext:$output
  );
}

def BGV_AddOp : BGV_Op<"add", [Pure, Commutative, SameOperandsAndResultRings, InferTypeOpAdaptor]> {
  let summary = "Addition operation between ciphertexts.";

  let arguments = (ins
    NewLWECiphertext:$lhs,
    NewLWECiphertext:$rhs
  );

  let results = (outs
    NewLWECiphertext:$output
  );
}

def BGV_AddPlainOp : BGV_CiphertextPlaintextOp<"add_plain"> {
  let summary = "Addition operation between ciphertext-plaintext.";
}

def BGV_SubOp : BGV_Op<"sub", [Pure, SameOperandsAndResultRings, InferTypeOpAdaptor]> {
  let summary = "Subtraction operation between ciphertexts.";

  let arguments = (ins
    NewLWECiphertext:$lhs,
    NewLWECiphertext:$rhs
  );

  let results = (outs
    NewLWECiphertext:$output
  );
}

def BGV_SubPlainOp : BGV_CiphertextPlaintextOp<"sub_plain"> {
  let summary = "Subtraction operation between ciphertext-plaintext.";
}

def BGV_MulOp : BGV_Op<"mul", [Pure, Commutative, SameOperandsAndResultRings, InferTypeOpAdaptor]> {
  let summary = "Multiplication operation between ciphertexts.";

  let arguments = (ins
    NewLWECiphertext:$lhs,
    NewLWECiphertext:$rhs
  );

  let results = (outs
    NewLWECiphertext:$output
  );

  let hasVerifier = 1;
}

def BGV_MulPlainOp : BGV_CiphertextPlaintextOp<"mul_plain"> {
  let summary = "Multiplication operation between ciphertext-plaintext.";
}

def BGV_RotateOp : BGV_Op<"rotate", [Pure, AllTypesMatch<["input", "output"]>]> {
  let summary = "Rotate the coefficients of the ciphertext using a Galois automorphism.";

  let arguments = (ins
    NewLWECiphertext:$input,
    Builtin_IntegerAttr:$offset
  );

  let results = (outs
    NewLWECiphertext:$output
  );

  let hasVerifier = 1;
  let assemblyFormat = "operands attr-dict `:` qualified(type($input))" ;
}

def BGV_ExtractOp : BGV_Op<"extract", [Pure, SameOperandsAndResultRings]> {
  let summary = "Extract the i-th element of a ciphertext.";

  let description = [{
    While this operation is costly to compute in FHE, we represent it so we can
    implement efficient lowerings and folders.

    This op can be implemented as a plaintext multiplication with a one-hot
    vector and a rotate into the zero-th index.

    An extraction op's input ciphertext type is asserted to have an `underlying_type`
    corresponding to a ranked tensor type, and this op's return type is
    inferred to have the `underlying_type` corresponding to the element type of
    that tensor type.
  }];

  let arguments = (ins
    NewLWECiphertext:$input,
    AnySignlessIntegerOrIndex:$offset
  );

  let results = (outs
    NewLWECiphertext:$output
  );

  let hasVerifier = 1;
}

def BGV_NegateOp : BGV_Op<"negate", [Pure, Involution, SameOperandsAndResultType]> {
  let summary = "Negate the coefficients of the ciphertext.";

  let arguments = (ins
    NewLWECiphertext:$input
  );

  let results = (outs
    NewLWECiphertext:$output
  );

  let assemblyFormat = "operands attr-dict `:` qualified(type($output))" ;
}

def BGV_RelinearizeOp : BGV_Op<"relinearize", [SameOperandsAndResultRings, InferTypeOpAdaptor]> {
  let summary = "Relinearize the ciphertext.";

  let description = [{
    This op takes integer array attributes `from_basis` and `to_basis` that are
    used to indicate the key basis from which and to which the ciphertext is
    encrypted against. A ciphertext is canonically encrypted against key basis
    `(1, s)`. After a multiplication, its size will increase and the basis will be
    `(1, s, s^2)`. The array that represents the key basis is constructed by
    listing the powers of `s` at each position of the array. For example, `(1, s,
    s^2)` corresponds to `[0, 1, 2]`, while `(1, s^2)` corresponds to `[0, 2]`.
  }];

  let arguments = (ins
    NewLWECiphertext:$input,
    DenseI32ArrayAttr:$from_basis,
    DenseI32ArrayAttr:$to_basis
  );

  let results = (outs
    NewLWECiphertext:$output
  );

  let hasVerifier = 1;
  let assemblyFormat = "operands attr-dict `:` qualified(type($input)) `->` qualified(type($output))" ;
}

def BGV_ModulusSwitchOp : BGV_Op<"modulus_switch"> {
  let summary = "Lower the modulus level of the ciphertext.";

  let arguments = (ins
    NewLWECiphertext:$input,
    Polynomial_RingAttr:$to_ring
  );

  let results = (outs
    NewLWECiphertext:$output
  );

  let hasVerifier = 1;
  let assemblyFormat = "operands attr-dict `:` qualified(type($input)) `->` qualified(type($output))" ;
}

#endif  // LIB_DIALECT_BGV_IR_BGVOPS_TD_

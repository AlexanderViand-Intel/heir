// RUN: heir-translate --emit-heracles-sdk %s | FileCheck %s
!Z1032955396097_i64_ = !mod_arith.int<1032955396097 : i64>
!Z1095233372161_i64_ = !mod_arith.int<1095233372161 : i64>
#inverse_canonical_encoding = #lwe.inverse_canonical_encoding<scaling_factor = 1024>
#key = #lwe.key<>
#modulus_chain_L5_C0_ = #lwe.modulus_chain<elements = <1095233372161 : i64, 1032955396097 : i64, 1005037682689 : i64, 998595133441 : i64, 972824936449 : i64, 959939837953 : i64>, current = 0>
#modulus_chain_L5_C1_ = #lwe.modulus_chain<elements = <1095233372161 : i64, 1032955396097 : i64, 1005037682689 : i64, 998595133441 : i64, 972824936449 : i64, 959939837953 : i64>, current = 1>
#ring_f64_1_x16384_ = #polynomial.ring<coefficientType = f64, polynomialModulus = <1 + x**16384>>
!rns_L0_ = !rns.rns<!Z1095233372161_i64_>
!rns_L1_ = !rns.rns<!Z1095233372161_i64_, !Z1032955396097_i64_>
#plaintext_space = #lwe.plaintext_space<ring = #ring_f64_1_x16384_, encoding = #inverse_canonical_encoding>
!pt = !lwe.new_lwe_plaintext<application_data = <message_type = i16>, plaintext_space = #plaintext_space>
#ring_rns_L0_1_x16384_ = #polynomial.ring<coefficientType = !rns_L0_, polynomialModulus = <1 + x**16384>>
#ring_rns_L1_1_x16384_ = #polynomial.ring<coefficientType = !rns_L1_, polynomialModulus = <1 + x**16384>>
!pkey_L1_ = !lwe.new_lwe_public_key<key = #key, ring = #ring_rns_L1_1_x16384_>
!skey_L0_ = !lwe.new_lwe_secret_key<key = #key, ring = #ring_rns_L0_1_x16384_>
#ciphertext_space_L0_ = #lwe.ciphertext_space<ring = #ring_rns_L0_1_x16384_, encryption_type = lsb>
#ciphertext_space_L1_ = #lwe.ciphertext_space<ring = #ring_rns_L1_1_x16384_, encryption_type = lsb>
#ciphertext_space_L1_D3_ = #lwe.ciphertext_space<ring = #ring_rns_L1_1_x16384_, encryption_type = lsb, size = 3>
!ct_L0_ = !lwe.new_lwe_ciphertext<application_data = <message_type = i16>, plaintext_space = #plaintext_space, ciphertext_space = #ciphertext_space_L0_, key = #key, modulus_chain = #modulus_chain_L5_C0_>
!ct_L1_ = !lwe.new_lwe_ciphertext<application_data = <message_type = i16>, plaintext_space = #plaintext_space, ciphertext_space = #ciphertext_space_L1_, key = #key, modulus_chain = #modulus_chain_L5_C1_>
!ct_L1_D3_ = !lwe.new_lwe_ciphertext<application_data = <message_type = i16>, plaintext_space = #plaintext_space, ciphertext_space = #ciphertext_space_L1_D3_, key = #key, modulus_chain = #modulus_chain_L5_C1_>
module attributes {scheme.ckks} {
  func.func @foo(%ct: !ct_L1_, %ct_0: !ct_L1_, %arg0: i16) -> (!ct_L1_, !ct_L1_, !ct_L1_, !ct_L1_, !ct_L1_, !ct_L1_D3_, !ct_L1_D3_, !ct_L1_, !ct_L1_, !ct_L0_, !ct_L1_) {
    // CHECK: instruction,scheme,poly_modulus_degree,rns_terms,arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9
    // FIXME: Add a pass that promotes cleartext args with no other uses than encode to plaintext function arguments and moves encoding to a client-side function
    %pt = lwe.rlwe_encode %arg0 {encoding = #inverse_canonical_encoding, ring = #ring_f64_1_x16384_} : i16 -> !pt
    // CHECK-NEXT: add, CKKS, 16384, 7, [[add:.*]], [[x:.*]], [[y:.*]]
    %add = ckks.add %ct, %ct_0 : (!ct_L1_, !ct_L1_) -> !ct_L1_
    // CHECK-NEXT: add_plain, CKKS, 16384, 7, [[addplain:.*]], [[x]], [[p:.*]]
    %add_plain = ckks.add_plain %ct, %pt : (!ct_L1_, !pt) -> !ct_L1_
    // CHECK-NEXT: sub, CKKS, 16384, 7, [[sub:.*]], [[x]], [[y]]
    %sub = ckks.sub %ct, %ct_0 : (!ct_L1_, !ct_L1_) -> !ct_L1_
    // CHECK-NEXT: sub_plain, CKKS, 16384, 7, [[subplain:.*]], [[x]], [[p]]
    %sub_plain = ckks.add_plain %ct, %pt : (!ct_L1_, !pt) -> !ct_L1_ // TODO: Remind Flavio to add sub_plain
    // CHECK-NEXT: negate, CKKS, 16384, 7, [[negate:.*]], [[x]]
    %negate = ckks.add %ct , %ct: (!ct_L1_, !ct_L1_) -> !ct_L1_ // FIXME: implement negate translation
    // CHECK-NEXT: mul, CKKS, 16384, 7, [[mul:.*]], [[x]], [[y]]
    %mul = ckks.mul %ct, %ct_0 : (!ct_L1_, !ct_L1_) -> !ct_L1_D3_
    // CHECK-NEXT: square, CKKS, 16384, 7, [[square:.*]], [[x]]
    %square = ckks.mul %ct, %ct : (!ct_L1_, !ct_L1_) -> !ct_L1_D3_
    // CHECK-NEXT: mul_plain, CKKS, 16384, 7, [[mulplain:.*]], [[x]], [[p]]
    %mul_plain = ckks.mul_plain %ct, %pt : (!ct_L1_, !pt) -> !ct_L1_
    // CHECK-NEXT: relin, CKKS, 16384, 7, [[relin:.*]], [[mul]]
    %relin = ckks.relinearize %mul {from_basis = array<i32: 0, 1, 2>, to_basis = array<i32: 0, 1>} : !ct_L1_D3_ -> !ct_L1_
    // CHECK-NEXT: rescale, CKKS, 16384, 7, [[rescale:.*]], [[relin]]
    %rescale = ckks.rescale %relin {to_ring = #ring_rns_L0_1_x16384_} : !ct_L1_ -> !ct_L0_
    // CHECK-NEXT: rotate, CKKS, 16384, 7, [[rotate:.*]], [[x]], 1
    %rotate = ckks.rotate %ct {offset = 1} : !ct_L1_
    return %add, %add_plain, %sub, %sub_plain, %negate, %mul, %square, %mul_plain, %relin, %rescale, %rotate : !ct_L1_, !ct_L1_, !ct_L1_, !ct_L1_, !ct_L1_, !ct_L1_D3_, !ct_L1_D3_, !ct_L1_, !ct_L1_, !ct_L0_, !ct_L1_
  }
    func.func @foo__encrypt__arg0(%cc: !openfhe.crypto_context, %arg0: i16, %pk: !openfhe.public_key) -> !ct_L1_ {
    %splat = tensor.splat %arg0 : tensor<16384xi16>
    %0 = arith.extsi %splat : tensor<16384xi16> to tensor<16384xi64>
    %pt = openfhe.make_ckks_packed_plaintext %cc, %0 : (!openfhe.crypto_context, tensor<16384xi64>) -> !pt
    %ct = openfhe.encrypt %cc, %pt, %pk : (!openfhe.crypto_context, !pt, !openfhe.public_key) -> !ct_L1_
    return %ct : !ct_L1_
  }
  func.func @foo__encrypt__arg1(%cc: !openfhe.crypto_context, %arg0: i16, %pk: !openfhe.public_key) -> !ct_L1_ {
    %splat = tensor.splat %arg0 : tensor<16384xi16>
    %0 = arith.extsi %splat : tensor<16384xi16> to tensor<16384xi64>
    %pt = openfhe.make_ckks_packed_plaintext %cc, %0 : (!openfhe.crypto_context, tensor<16384xi64>) -> !pt
    %ct = openfhe.encrypt %cc, %pt, %pk : (!openfhe.crypto_context, !pt, !openfhe.public_key) -> !ct_L1_
    return %ct : !ct_L1_
  }
  func.func @foo__decrypt__result0(%cc: !openfhe.crypto_context, %ct: !ct_L0_, %sk: !openfhe.private_key) -> i16 {
    %pt = openfhe.decrypt %cc, %ct, %sk : (!openfhe.crypto_context, !ct_L0_, !openfhe.private_key) -> !pt
    %0 = lwe.rlwe_decode %pt {encoding = #inverse_canonical_encoding, ring = #ring_f64_1_x16384_} : !pt -> i16
    return %0 : i16
  }
  func.func @foo__decrypt__result1(%cc: !openfhe.crypto_context, %ct: !ct_L0_, %sk: !openfhe.private_key) -> i16 {
    %pt = openfhe.decrypt %cc, %ct, %sk : (!openfhe.crypto_context, !ct_L0_, !openfhe.private_key) -> !pt
    %0 = lwe.rlwe_decode %pt {encoding = #inverse_canonical_encoding, ring = #ring_f64_1_x16384_} : !pt -> i16
    return %0 : i16
  }
  func.func @foo__decrypt__result2(%cc: !openfhe.crypto_context, %ct: !ct_L0_, %sk: !openfhe.private_key) -> i16 {
    %pt = openfhe.decrypt %cc, %ct, %sk : (!openfhe.crypto_context, !ct_L0_, !openfhe.private_key) -> !pt
    %0 = lwe.rlwe_decode %pt {encoding = #inverse_canonical_encoding, ring = #ring_f64_1_x16384_} : !pt -> i16
    return %0 : i16
  }
  func.func @foo__decrypt__result3(%cc: !openfhe.crypto_context, %ct: !ct_L0_, %sk: !openfhe.private_key) -> i16 {
    %pt = openfhe.decrypt %cc, %ct, %sk : (!openfhe.crypto_context, !ct_L0_, !openfhe.private_key) -> !pt
    %0 = lwe.rlwe_decode %pt {encoding = #inverse_canonical_encoding, ring = #ring_f64_1_x16384_} : !pt -> i16
    return %0 : i16
  }
  func.func @foo__decrypt__result4(%cc: !openfhe.crypto_context, %ct: !ct_L0_, %sk: !openfhe.private_key) -> i16 {
    %pt = openfhe.decrypt %cc, %ct, %sk : (!openfhe.crypto_context, !ct_L0_, !openfhe.private_key) -> !pt
    %0 = lwe.rlwe_decode %pt {encoding = #inverse_canonical_encoding, ring = #ring_f64_1_x16384_} : !pt -> i16
    return %0 : i16
  }
  func.func @foo__decrypt__result5(%cc: !openfhe.crypto_context, %ct: !ct_L0_, %sk: !openfhe.private_key) -> i16 {
    %pt = openfhe.decrypt %cc, %ct, %sk : (!openfhe.crypto_context, !ct_L0_, !openfhe.private_key) -> !pt
    %0 = lwe.rlwe_decode %pt {encoding = #inverse_canonical_encoding, ring = #ring_f64_1_x16384_} : !pt -> i16
    return %0 : i16
  }
  func.func @foo__generate_crypto_context() -> !openfhe.crypto_context {
    %params = openfhe.gen_params  {evalAddCount = 0 : i64, insecure = false, keySwitchCount = 0 : i64, mulDepth = 1 : i64, plainMod = 0 : i64} : () -> !openfhe.cc_params
    %cc = openfhe.gen_context %params {supportFHE = false} : (!openfhe.cc_params) -> !openfhe.crypto_context
    return %cc : !openfhe.crypto_context
  }
  func.func @foo__configure_crypto_context(%cc: !openfhe.crypto_context, %sk: !openfhe.private_key) -> !openfhe.crypto_context {
    openfhe.gen_mulkey %cc, %sk : (!openfhe.crypto_context, !openfhe.private_key) -> ()
    openfhe.gen_rotkey %cc, %sk {indices = array<i64: 1>} : (!openfhe.crypto_context, !openfhe.private_key) -> ()
    return %cc : !openfhe.crypto_context
  }
  // FIXME: We should also emit a @foo_encode_arg2 function since HERACLES cannot directly consume cleartext values!


  // func.func @basic(%ct: !ct_L1_, %ct_0: !ct_L1_) -> (!ct_L1_) {
  //   %add = ckks.add %ct, %ct_0 : (!ct_L1_, !ct_L1_) -> !ct_L1_
  //   return %add: !ct_L1_
  // }
}




// func.func @foo(%x: i16 {secret.secret}, %y: i16 {secret.secret}, %p: i16) -> (i16, i16, i16, i16, i16, i16) {
//   %1 = arith.addi %x, %y : i16
//   %2 = arith.addi %x, %p : i16
//   %3 = arith.subi %x, %y : i16
//   // %4 = arith.subi %x, %p : i16
//   // %5 = <negate>   %x
//   %6 = arith.muli %x, %y : i16
//   %7 = arith.muli %x, %x : i16
//   %8 = arith.muli %x, %p : i16
//   // %9 = <relin> %6
//   // %10= <rescale> 89
//   // %11= tensor_ext.rotate %x, 1 : i16
//   return %1, %2, %3, %6, %7,%8 : i16, i16, i16, i16, i16, i16
// }

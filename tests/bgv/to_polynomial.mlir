// RUN: heir-opt --bgv-to-polynomial %s > %t
// RUN: FileCheck %s < %t

// This simply tests for syntax.

#encoding = #lwe.polynomial_evaluation_encoding<cleartext_start=30, cleartext_bitwidth=3>

#my_poly = #polynomial.int_polynomial<1 + x**1024>
#ring = #polynomial.ring<coefficientType = i32, coefficientModulus = 33538049 : i32, polynomialModulus=#my_poly>
#params = #lwe.rlwe_params<dimension=2, ring=#ring>
#params1 = #lwe.rlwe_params<dimension=3, ring=#ring>

!ct = !lwe.rlwe_ciphertext<encoding=#encoding, rlwe_params=#params, underlying_type=i32>
!ct1 = !lwe.rlwe_ciphertext<encoding=#encoding, rlwe_params=#params1, underlying_type=i32>

module {
  // CHECK-LABEL: func.func @test_fn
  // CHECK-SAME: ([[X:%.+]]: [[T:tensor<2x!polynomial.*33538049.*]]) -> [[T]] {
  func.func @test_fn(%x : !ct) -> !ct {
    // CHECK: return [[X]] : [[T]]
    return %x : !ct
  }


  // CHECK-LABEL: func.func @test_bin_ops
  // CHECK-SAME: ([[X:%.+]]: [[T:tensor<2x!polynomial.*33538049.*]], [[Y:%.+]]: [[T]]) {
  func.func @test_bin_ops(%x : !ct, %y : !ct) {
    // CHECK: polynomial.add [[X]], [[Y]] : [[T]]
    %add = bgv.add %x, %y  : !ct
    // CHECK: polynomial.sub [[X]], [[Y]] : [[T]]
    %sub = bgv.sub %x, %y  : !ct
    // CHECK: [[C:%.+]] = arith.constant -1 : [[I:.+]]
    // CHECK: polynomial.mul_scalar [[X]], [[C]] : [[T]], [[I]]
    %negate = bgv.negate %x  : !ct

    // CHECK: [[I0:%.+]] = arith.constant 0 : index
    // CHECK: [[I1:%.+]] = arith.constant 1 : index
    // CHECK: [[X0:%.+]] = tensor.extract [[X]][[[I0]]] : [[T]]
    // CHECK: [[X1:%.+]] = tensor.extract [[X]][[[I1]]] : [[T]]
    // CHECK: [[Y0:%.+]] = tensor.extract [[Y]][[[I0]]] : [[T]]
    // CHECK: [[Y1:%.+]] = tensor.extract [[Y]][[[I1]]] : [[T]]
    // CHECK: [[Z0:%.+]] = polynomial.mul [[X0]], [[Y0]] : [[P:!polynomial.*33538049.*]]
    // CHECK: [[X0Y1:%.+]] = polynomial.mul [[X0]], [[Y1]] : [[P]]
    // CHECK: [[X1Y0:%.+]] = polynomial.mul [[X1]], [[Y0]] : [[P]]
    // CHECK: [[Z1:%.+]] = polynomial.add [[X0Y1]], [[X1Y0]] : [[P]]
    // CHECK: [[Z2:%.+]] = polynomial.mul [[X1]], [[Y1]] : [[P]]
    // CHECK: [[Z:%.+]] = tensor.from_elements [[Z0]], [[Z1]], [[Z2]] : tensor<3x[[P]]>
    %mul = bgv.mul %x, %y  : (!ct, !ct) -> !ct1
    return
  }
}

module {
   // CHECK-LABEL: func.func @test_relin([[X:%.+]]: [[T1:tensor<3x!polynomial.*33538049.*]]: [[T:tensor<2x!polynomial.*33538049.*]]) {
  func.func @test_relin(%arg0 : !ct1) -> !ct {
    // TODO: Define expected output for relinearize
    %r = bgv.relinearize %arg0  {from_basis = array<i32: 0, 1, 2>, to_basis = array<i32: 0, 1> } : !ct1 -> !ct
    return %r : !ct
  }
}
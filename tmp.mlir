module {
  func.func @foo(%arg0: !secret.secret<tensor<8192xi64>>, %arg1: !secret.secret<tensor<8192xi64>>) -> !secret.secret<tensor<8192xi64>> {
    %0 = secret.generic ins(%arg0, %arg1 : !secret.secret<tensor<8192xi64>>, !secret.secret<tensor<8192xi64>>) {
    ^bb0(%arg2: tensor<8192xi64>, %arg3: tensor<8192xi64>):
      %1 = arith.muli %arg3, %arg3 : tensor<8192xi64>
      %2 = arith.muli %arg2, %arg2 : tensor<8192xi64>
      %3 = arith.subi %2, %1 : tensor<8192xi64>
      secret.yield %3 : tensor<8192xi64>
    } -> !secret.secret<tensor<8192xi64>>
    return %0 : !secret.secret<tensor<8192xi64>>
  }
  func.func @foo_secret(%arg0: !secret.secret<tensor<8192xi64>>, %arg1: !secret.secret<tensor<8192xi64>>) -> !secret.secret<tensor<8192xi64>> {
    %0 = secret.generic ins(%arg0, %arg1 : !secret.secret<tensor<8192xi64>>, !secret.secret<tensor<8192xi64>>) {
    ^bb0(%arg2: tensor<8192xi64>, %arg3: tensor<8192xi64>):
      %1 = arith.muli %arg3, %arg3 : tensor<8192xi64>
      %2 = arith.muli %arg2, %arg2 : tensor<8192xi64>
      %3 = arith.subi %2, %1 : tensor<8192xi64>
      secret.yield %3 : tensor<8192xi64>
    } -> !secret.secret<tensor<8192xi64>>
    return %0 : !secret.secret<tensor<8192xi64>>
  }
  func.func @foo_vec(%arg0: tensor<8192xi64>, %arg1: tensor<8192xi64>) -> tensor<8192xi64> {
    %0 = arith.muli %arg1, %arg1 : tensor<8192xi64>
    %1 = arith.muli %arg0, %arg0 : tensor<8192xi64>
    %2 = arith.subi %1, %0 : tensor<8192xi64>
    return %2 : tensor<8192xi64>
  }
  func.func @foo_bgv(%arg0: !lwe.rlwe_ciphertext<encoding = #lwe.polynomial_evaluation_encoding<cleartext_start = 64, cleartext_bitwidth = 64>, rlwe_params = <ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, underlying_type = tensor<8192xi64>>, %arg1: !lwe.rlwe_ciphertext<encoding = #lwe.polynomial_evaluation_encoding<cleartext_start = 64, cleartext_bitwidth = 64>, rlwe_params = <ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, underlying_type = tensor<8192xi64>>) -> !lwe.rlwe_ciphertext<encoding = #lwe.polynomial_evaluation_encoding<cleartext_start = 64, cleartext_bitwidth = 64>, rlwe_params = <dimension = 3, ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, underlying_type = tensor<8192xi64>> {
    %0 = bgv.mul %arg1, %arg1 : (!lwe.rlwe_ciphertext<encoding = #lwe.polynomial_evaluation_encoding<cleartext_start = 64, cleartext_bitwidth = 64>, rlwe_params = <ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, underlying_type = tensor<8192xi64>>, !lwe.rlwe_ciphertext<encoding = #lwe.polynomial_evaluation_encoding<cleartext_start = 64, cleartext_bitwidth = 64>, rlwe_params = <ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, underlying_type = tensor<8192xi64>>) -> !lwe.rlwe_ciphertext<encoding = #lwe.polynomial_evaluation_encoding<cleartext_start = 64, cleartext_bitwidth = 64>, rlwe_params = <dimension = 3, ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, underlying_type = tensor<8192xi64>>
    %1 = bgv.mul %arg0, %arg0 : (!lwe.rlwe_ciphertext<encoding = #lwe.polynomial_evaluation_encoding<cleartext_start = 64, cleartext_bitwidth = 64>, rlwe_params = <ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, underlying_type = tensor<8192xi64>>, !lwe.rlwe_ciphertext<encoding = #lwe.polynomial_evaluation_encoding<cleartext_start = 64, cleartext_bitwidth = 64>, rlwe_params = <ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, underlying_type = tensor<8192xi64>>) -> !lwe.rlwe_ciphertext<encoding = #lwe.polynomial_evaluation_encoding<cleartext_start = 64, cleartext_bitwidth = 64>, rlwe_params = <dimension = 3, ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, underlying_type = tensor<8192xi64>>
    %2 = bgv.sub %0, %1 : !lwe.rlwe_ciphertext<encoding = #lwe.polynomial_evaluation_encoding<cleartext_start = 64, cleartext_bitwidth = 64>, rlwe_params = <dimension = 3, ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, underlying_type = tensor<8192xi64>>
    return %2 : !lwe.rlwe_ciphertext<encoding = #lwe.polynomial_evaluation_encoding<cleartext_start = 64, cleartext_bitwidth = 64>, rlwe_params = <dimension = 3, ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, underlying_type = tensor<8192xi64>>
  }
}

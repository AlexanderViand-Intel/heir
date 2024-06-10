!t = tensor<8192xi64>
#ring = #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>
#encoding =  #lwe.polynomial_evaluation_encoding<cleartext_start = 64, cleartext_bitwidth = 64>
#rlwe_params2 = #lwe.rlwe_params<dimension = 2, ring = #ring>
#rlwe_params3 = #lwe.rlwe_params<dimension = 3, ring = #ring>
!ctxt2 = !lwe.rlwe_ciphertext<encoding = #encoding, rlwe_params = #rlwe_params2 , underlying_type = !t>
!ctxt3 = !lwe.rlwe_ciphertext<encoding = #encoding, rlwe_params = #rlwe_params3, underlying_type = !t>

func.func @foo_vec_sec(%arg0: !ctxt2, %arg1: !ctxt2) -> !ctxt3 {
  %0 = bgv.mul %arg1, %arg1 : (!ctxt2, !ctxt2) -> !ctxt3
  %1 = bgv.mul %arg0, %arg0 : (!ctxt2, !ctxt2) -> !ctxt3
  %2 = bgv.sub %0, %1 : !ctxt3
  return %2 : !ctxt3
}

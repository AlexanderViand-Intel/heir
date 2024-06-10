// example high-level input from frontend (e.g., Polygeist, MLIR's C/C++)
!t = tensor<8192xi64>
func.func @foo(%x : !t, %y : !t ) -> !t {
    %0 = affine.for %i = 0 to 8192 iter_args(%yy = %y) -> !t {
        %xi = tensor.extract %x[%i] : !t
        %yi = tensor.extract %y[%i] : !t
        %x2 = arith.muli %xi, %xi : i64
        %y2 = arith.muli %yi, %yi : i64
        %s = arith.subi %x2, %y2 : i64
        %r = tensor.insert %s into %yy[%i] : !t
        affine.yield %r : !t
    }
    func.return %0 : !t
}

// We provide a helper pass `--secretize=entry-function=` that makes it easy to annotate
// a function's arguments as secret (which is requyired to enable lowering to BGV)
// `heir-opt --secretize=entry-function=foo --wrap-generic --heir-simd-vectorizer example.mlir`
!st = !secret.secret<!t>
func.func @foo_secret(%arg0: !st, %arg1: !st) -> !st {
    %0 = secret.generic ins(%arg0, %arg1 : !st, !st) {
    ^bb0(%arg2: !t, %arg3: !t):
        %1 = affine.for %arg4 = 0 to 8192 iter_args(%arg5 = %arg3) -> (!t) {
        %extracted = tensor.extract %arg2[%arg4] : !t
        %extracted_0 = tensor.extract %arg3[%arg4] : !t
        %2 = arith.muli %extracted, %extracted : i64
        %3 = arith.muli %extracted_0, %extracted_0 : i64
        %4 = arith.subi %2, %3 : i64
        %inserted = tensor.insert %4 into %arg5[%arg4] : !t
        affine.yield %inserted : !t
        }
        secret.yield %1 : !t
    } -> !st
    return %0 : !st
}

// turns into via HECO-style batching op integrated into HEIR:
// heir-opt --heir-simd-vectorizer example.mlir
func.func @foo_vec(%x: !t, %y: !t) -> !t {
    %0 = arith.muli %y, %y : !t
    %1 = arith.muli %x, %x : !t
    %2 = arith.subi %1, %0 : !t
    return %2 : !t
}



// Lowering to BGV
// heir-opt --secret-distribute-generic --secret-to-bgv="poly-mod-degree=8192"
#ring = #polynomial.ring<coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>
#encoding =  #lwe.polynomial_evaluation_encoding<cleartext_start = 64, cleartext_bitwidth = 64>
#rlwe_params2 = #lwe.rlwe_params<dimension = 2, ring = #ring>
#rlwe_params3 = #lwe.rlwe_params<dimension = 3, ring = #ring>
!ctxt2 = !lwe.rlwe_ciphertext<encoding = #encoding, rlwe_params = #rlwe_params2 , underlying_type = !t>
!ctxt3 = !lwe.rlwe_ciphertext<encoding = #encoding, rlwe_params = #rlwe_params3, underlying_type = !t>

func.func @foo_bgv(%x: !ctxt2, %y: !ctxt2) -> !ctxt3 {
  %0 = bgv.mul %y, %y : (!ctxt2, !ctxt2) -> !ctxt3
  %1 = bgv.mul %x, %x : (!ctxt2, !ctxt2) -> !ctxt3
  %2 = bgv.sub %0, %1 : !ctxt3
  return %2 : !ctxt3
}

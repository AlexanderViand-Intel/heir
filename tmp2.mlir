module {
  func.func @foo_vec_sec(%arg0: tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>, %arg1: tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>) -> tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>> {
    %c2 = arith.constant 2 : index
    %c-1_i32 = arith.constant -1 : i32
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %extracted = tensor.extract %arg1[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %extracted_0 = tensor.extract %arg1[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %0 = polynomial.ntt %extracted : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %1 = arith_ext.mul %0, %0 {modulus = 463187969 : i32} : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %2 = polynomial.intt %1 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> <ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %3 = polynomial.ntt %extracted_0 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %4 = arith_ext.mul %0, %3 {modulus = 463187969 : i32} : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %5 = polynomial.intt %4 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> <ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %6 = polynomial.add %5, %5 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %7 = arith_ext.mul %3, %3 {modulus = 463187969 : i32} : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %8 = polynomial.intt %7 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> <ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %extracted_1 = tensor.extract %arg0[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %extracted_2 = tensor.extract %arg0[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %9 = polynomial.ntt %extracted_1 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %10 = arith_ext.mul %9, %9 {modulus = 463187969 : i32} : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %11 = polynomial.intt %10 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> <ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %12 = polynomial.ntt %extracted_2 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %13 = arith_ext.mul %9, %12 {modulus = 463187969 : i32} : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %14 = polynomial.intt %13 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> <ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %15 = polynomial.add %14, %14 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %16 = arith_ext.mul %12, %12 {modulus = 463187969 : i32} : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %17 = polynomial.intt %16 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> <ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %18 = tensor.empty() : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %19 = polynomial.mul_scalar %11, %c-1_i32 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>, i32
    %20 = polynomial.add %2, %19 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %inserted = tensor.insert %20 into %18[%c0] : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %21 = polynomial.mul_scalar %15, %c-1_i32 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>, i32
    %22 = polynomial.add %6, %21 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %inserted_3 = tensor.insert %22 into %inserted[%c1] : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %23 = polynomial.mul_scalar %17, %c-1_i32 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>, i32
    %24 = polynomial.add %8, %23 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %inserted_4 = tensor.insert %24 into %inserted_3[%c2] : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    return %inserted_4 : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
  }
}

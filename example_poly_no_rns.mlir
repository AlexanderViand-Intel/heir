module {
  func.func @foo_vec_sec(%arg0: tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>, %arg1: tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>) -> tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>> {
    %c2 = arith.constant 2 : index
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %extracted = tensor.extract %arg1[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %extracted_0 = tensor.extract %arg1[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %0 = polynomial.ntt %extracted : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %1 = arith_ext.mul %0, %0 {modulus = 463187969 : i32} : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %2 = polynomial.ntt %extracted_0 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %3 = arith_ext.mul %0, %2 {modulus = 463187969 : i32} : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %4 = arith.addi %3, %3 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %5 = arith_ext.mul %2, %2 {modulus = 463187969 : i32} : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %extracted_1 = tensor.extract %arg0[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %extracted_2 = tensor.extract %arg0[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %6 = polynomial.ntt %extracted_1 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %7 = arith_ext.mul %6, %6 {modulus = 463187969 : i32} : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %8 = polynomial.ntt %extracted_2 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %9 = arith_ext.mul %6, %8 {modulus = 463187969 : i32} : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %10 = arith.addi %9, %9 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %11 = arith_ext.mul %8, %8 {modulus = 463187969 : i32} : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %12 = tensor.empty() : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %13 = arith.subi %1, %7 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %14 = polynomial.intt %13 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> <ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %inserted = tensor.insert %14 into %12[%c0] : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %15 = arith.subi %4, %10 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %16 = polynomial.intt %15 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> <ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %inserted_3 = tensor.insert %16 into %inserted[%c1] : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    %17 = arith.subi %5, %11 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %18 = polynomial.intt %17 : tensor<8192xi32, #polynomial.ring<coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>> -> <ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>
    %inserted_4 = tensor.insert %18 into %inserted_3[%c2] : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
    return %inserted_4 : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**8192>>>>
  }
}

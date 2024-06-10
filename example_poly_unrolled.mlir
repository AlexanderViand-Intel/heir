module {
  func.func @foo_poly(%arg0: tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>, %arg1: tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>) -> tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>> {
    %c2 = arith.constant 2 : index
    %c-1_i32 = arith.constant -1 : i32
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %extracted = tensor.extract %arg1[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %extracted_0 = tensor.extract %arg1[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %0 = polynomial.mul %extracted, %extracted : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %1 = polynomial.mul %extracted, %extracted_0 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %2 = polynomial.add %1, %1 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %3 = polynomial.mul %extracted_0, %extracted_0 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %extracted_1 = tensor.extract %arg0[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %extracted_2 = tensor.extract %arg0[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %4 = polynomial.mul %extracted_1, %extracted_1 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %5 = polynomial.mul %extracted_1, %extracted_2 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %6 = polynomial.add %5, %5 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %7 = polynomial.mul %extracted_2, %extracted_2 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %8 = tensor.empty() : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %9 = polynomial.mul_scalar %4, %c-1_i32 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, i32
    %10 = polynomial.add %0, %9 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %inserted = tensor.insert %10 into %8[%c0] : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %11 = polynomial.mul_scalar %6, %c-1_i32 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, i32
    %12 = polynomial.add %2, %11 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %inserted_3 = tensor.insert %12 into %inserted[%c1] : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %13 = polynomial.mul_scalar %7, %c-1_i32 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>, i32
    %14 = polynomial.add %3, %13 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %inserted_4 = tensor.insert %14 into %inserted_3[%c2] : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    return %inserted_4 : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
  }
}

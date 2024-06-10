 func.func @foo_poly(%arg0: tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>, %arg1: tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>) -> tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>> {
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %extracted = tensor.extract %arg1[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %extracted_0 = tensor.extract %arg1[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %extracted_1 = tensor.extract %arg1[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %extracted_2 = tensor.extract %arg1[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %0 = polynomial.mul %extracted, %extracted_1 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %1 = polynomial.mul %extracted, %extracted_2 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %2 = polynomial.mul %extracted_0, %extracted_1 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %3 = polynomial.add %1, %2 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %4 = polynomial.mul %extracted_0, %extracted_2 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %from_elements = tensor.from_elements %0, %3, %4 : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %c0_3 = arith.constant 0 : index
    %c1_4 = arith.constant 1 : index
    %extracted_5 = tensor.extract %arg0[%c0_3] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %extracted_6 = tensor.extract %arg0[%c1_4] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %extracted_7 = tensor.extract %arg0[%c0_3] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %extracted_8 = tensor.extract %arg0[%c1_4] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %5 = polynomial.mul %extracted_5, %extracted_7 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %6 = polynomial.mul %extracted_5, %extracted_8 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %7 = polynomial.mul %extracted_6, %extracted_7 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %8 = polynomial.add %6, %7 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %9 = polynomial.mul %extracted_6, %extracted_8 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>
    %from_elements_9 = tensor.from_elements %5, %8, %9 : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    %10 = polynomial.sub %from_elements, %from_elements_9 : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
    return %10 : tensor<3x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModuli = dense<[463187969, 679389209, 383838383]> : tensor<3xi32>, polynomialModulus = <1 + x**8192>>>>
  }

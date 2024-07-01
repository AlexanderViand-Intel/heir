module {
  func.func @foo(%arg0: tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>, %arg1: tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>) -> tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>> {
    %c1 = arith.constant 1 : index
    %c0 = arith.constant 0 : index
    %0 = tensor.empty() : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %extracted = tensor.extract %arg1[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %1 = polynomial.add %extracted, %extracted : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>
    %inserted = tensor.insert %1 into %0[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %extracted_0 = tensor.extract %arg1[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %2 = polynomial.add %extracted_0, %extracted_0 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>
    %inserted_1 = tensor.insert %2 into %inserted[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %extracted_2 = tensor.extract %arg0[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %3 = polynomial.add %extracted_2, %extracted_2 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>
    %inserted_3 = tensor.insert %3 into %0[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %extracted_4 = tensor.extract %arg0[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %4 = polynomial.add %extracted_4, %extracted_4 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>
    %inserted_5 = tensor.insert %4 into %inserted_3[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %extracted_6 = tensor.extract %inserted_5[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %extracted_7 = tensor.extract %inserted_1[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %5 = polynomial.sub %extracted_6, %extracted_7 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>
    %inserted_8 = tensor.insert %5 into %0[%c0] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %extracted_9 = tensor.extract %inserted_5[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %extracted_10 = tensor.extract %inserted_1[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    %6 = polynomial.sub %extracted_9, %extracted_10 : !polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>
    %inserted_11 = tensor.insert %6 into %inserted_8[%c1] : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
    return %inserted_11 : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**128>>>>
  }
}

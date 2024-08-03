module {
  func.func @basic_test(%arg0: tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**4096>>>>, %arg1: tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**4096>>>>) -> tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**4096>>>> {
    %0 = polynomial.add %arg0, %arg1 : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**4096>>>>
    return %0 : tensor<2x!polynomial.polynomial<ring = <coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**4096>>>>
  }
}

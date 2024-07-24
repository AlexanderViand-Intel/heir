// RUN: heir-opt --canonicalize --secret-to-bgv %s | FileCheck %s

!eui1 = !secret.secret<tensor<1024xi1>>
!eui32 = !secret.secret<tensor<1024xi32>>

module {
  // CHECK-LABEL: func @test_arith_ops
  func.func @test_arith_ops(%arg0 : !eui1, %arg1 : !eui1, %arg2 : !eui1) -> (!eui1) {
    %0 = secret.generic ins(%arg0, %arg1 :  !eui1, !eui1) {
    // CHECK: bgv.add
      ^bb0(%ARG0 : tensor<1024xi1>, %ARG1 : tensor<1024xi1>):
        %1 = arith.addi %ARG0, %ARG1 : tensor<1024xi1>
        secret.yield %1 : tensor<1024xi1>
    } -> !eui1
    // CHECK: bgv.mul
    // CHECK-NEXT: bgv.relinearize
    %1 = secret.generic ins(%0, %arg2 :  !eui1, !eui1) {
      ^bb0(%ARG0 : tensor<1024xi1>, %ARG1 : tensor<1024xi1>):
        %1 = arith.muli %ARG0, %ARG1 : tensor<1024xi1>
        secret.yield %1 : tensor<1024xi1>
    } -> !eui1
    // CHECK: return
    // CHECK-SAME: coefficientType = i32, coefficientModulus = 463187969 : i32, polynomialModulus = <1 + x**1024>
    return %1 : !eui1
  }
}

//CHECK-LABEL: func @test_arith_select
func.func @test_arith_select(%cond : !eui1, %lhs : !eui32, %rhs : !eui32) ->  !eui32 {
    %0 = secret.generic ins(%cond, %lhs, %rhs :  !eui1, !eui32, !eui32) {
    ^bb0(%COND : tensor<1024xi1>, %LHS : tensor<1024xi32>, %RHS : tensor<1024xi32>):
      %1 = arith.select %COND, %LHS, %RHS : tensor<1024xi1>, tensor<1024xi32>
      secret.yield %1 : tensor<1024xi32>
  } -> !eui32
  return %0 : !eui32
}

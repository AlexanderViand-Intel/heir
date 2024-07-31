// RUN: heir-opt --select-rewrite %s | FileCheck %s

// CHECK-LABEL: func @scalar_arith_select
// CHECK-SAME: [[COND:%.*]]: i1, [[LHS:%.*]]: i32, [[RHS:%.*]]: i32
func.func @scalar_arith_select(%cond : i1, %lhs : i32, %rhs : i32) ->  i32 {
    // CHECK: [[ONE:%.*]] = arith.constant true
    // CHECK-DAG: [[NCOND:%.*]] = arith.subi [[ONE]], [[COND]]
    // CHECK-DAG: [[XCOND:%.*]] = arith.extui [[COND]]
    // CHECK-DAG: [[XNCOND:%.*]] = arith.extui [[NCOND]]
    // CHECK-DAG: [[MLHS:%.*]] = arith.muli [[XCOND]], [[LHS]]
    // CHECK-DAG: [[MRHS:%.*]] = arith.muli [[XNCOND]], [[RHS]]
    // CHECK: [[RES:%.*]] = arith.addi [[MLHS]], [[MRHS]]
    // CHECK-NOT: arith.select
    %0 = arith.select %cond, %lhs, %rhs : i32
    // CHECK: return [[RES:%.*]] : i32
    return %0 : i32
}

// CHECK-LABEL: func @vector_arith_select
// CHECK: [[COND:%.*]]: tensor<2xi1>, [[LHS:%.*]]: tensor<2xi32>, [[RHS:%.*]]: tensor<2xi32>
func.func @vector_arith_select(%cond : tensor<2xi1>, %lhs : tensor<2xi32>, %rhs : tensor<2xi32>) ->  tensor<2xi32> {
    // CHECK: [[ONE:%.*]] = arith.constant dense<true>
    // CHECK-DAG: [[NCOND:%.*]] = arith.subi [[ONE]], [[COND]]
    // CHECK-DAG: [[XCOND:%.*]] = arith.extui [[COND]]
    // CHECK-DAG: [[XNCOND:%.*]] = arith.extui [[NCOND]]
    // CHECK-DAG: [[MLHS:%.*]] = arith.muli [[XCOND]], [[LHS]]
    // CHECK-DAG: [[MRHS:%.*]] = arith.muli [[XNCOND]], [[RHS]]
    // CHECK: [[RES:%.*]] = arith.addi [[MLHS]], [[MRHS]]
    // CHECK-NOT: arith.select
    %0 = arith.select %cond, %lhs, %rhs :  tensor<2xi1>, tensor<2xi32>
    // CHECK: return [[RES:%.*]] : tensor<2xi32>
    return %0 :  tensor<2xi32>
}

// FIXME: this case is not currently handled correctly!
// CHECK-LABEL: func @mixed_arith_select
func.func @mixed_arith_select(%cond : i1, %lhs : tensor<2xi32>, %rhs : tensor<2xi32>) ->  tensor<2xi32> {
    // CHECK-NOT: arith.select
    %0 = arith.select %cond, %lhs, %rhs : i1, tensor<2xi32>
    return %0 : tensor<2xi32>
}

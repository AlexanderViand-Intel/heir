module {
  func.func @foo(%arg0: !secret.secret<i32>, %arg1: i32) -> !secret.secret<i32> {
    %0 = arith.addi %arg1, %arg1 : i32
    %1 = arith.subi %arg1, %0 : i32
    return %1 : i32
  }
}

func.func @foo(%unused: i32 {secret.secret}, %arg1: i32) -> i32 {
  %1 = arith.addi %arg1, %arg1 : i32
  %2 = arith.subi %arg1, %1 : i32
  return %2 : i32
}

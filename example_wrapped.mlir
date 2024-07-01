module {
  func.func @foo(%arg0: !secret.secret<i32>, %arg1: i32) -> !secret.secret<i32> {
    %11 = tensor.from_elements %arg0 : tensor<1x!secret.secret<i32>>
    %c0 = arith.constant 0 : index
    %12 = tensor.insert %arg0 into %11[%c0] : tensor<1x!secret.secret<i32>>
    %01 = affine.for %i = 0 to 100 iter_args(%x = %arg0) -> (!secret.secret<i32>) {
      %0 = secret.generic ins(%arg0, %arg1 : !secret.secret<i32>, i32) {
      ^bb0(%arg2: i32, %arg3: i32):
        %1 = arith.addi %arg2, %arg2 : i32
        %2 = arith.addi %arg3, %arg3 : i32
        %3 = arith.subi %1, %2 {youranalaysisthing = 17} : i32
        secret.yield %3 : i32
      } -> !secret.secret<i32>
      affine.yield %0 : !secret.secret<i32>
    }
    return %01 : !secret.secret<i32>
  }
}

#map = affine_map<() -> (0)>
#map1 = affine_map<() -> (100)>
"builtin.module"() ({
  "func.func"() <{function_type = (!secret.secret<i32>, i32) -> !secret.secret<i32>, sym_name = "foo"}> ({
  ^bb0(%arg0: !secret.secret<i32>, %arg1: i32):
    %0 = "tensor.from_elements"(%arg0) : (!secret.secret<i32>) -> tensor<1x!secret.secret<i32>>
    %1 = "arith.constant"() <{value = 0 : index}> : () -> index
    %2 = "tensor.insert"(%arg0, %0, %1) : (!secret.secret<i32>, tensor<1x!secret.secret<i32>>, index) -> tensor<1x!secret.secret<i32>>
    %3 = "affine.for"(%arg0) <{lowerBoundMap = #map, operandSegmentSizes = array<i32: 0, 0, 1>, step = 1 : index, upperBoundMap = #map1}> ({
    ^bb0(%arg2: index, %arg3: !secret.secret<i32>):
      %4 = "secret.generic"(%arg0, %arg1) ({
      ^bb0(%arg4: i32, %arg5: i32):
        %5 = "arith.addi"(%arg4, %arg4) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
        %6 = "arith.addi"(%arg5, %arg5) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
        %7 = "arith.subi"(%5, %6) <{overflowFlags = #arith.overflow<none>}> {youranalaysisthing = 17 : i64} : (i32, i32) -> i32
        "secret.yield"(%7) : (i32) -> ()
      }) : (!secret.secret<i32>, i32) -> !secret.secret<i32>
      "affine.yield"(%4) : (!secret.secret<i32>) -> ()
    }) : (!secret.secret<i32>) -> !secret.secret<i32>
    "func.return"(%3) : (!secret.secret<i32>) -> ()
  }) : () -> ()
}) : () -> ()

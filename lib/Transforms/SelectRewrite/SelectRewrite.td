#ifndef LIB_TRANSFORMS_SelectRewrite_SelectRewrite_TD_
#define LIB_TRANSFORMS_SelectRewrite_SelectRewrite_TD_

include "lib/DRR/Utils.td"
include "mlir/Dialect/Arith/IR/ArithOps.td"
include "mlir/Pass/PassBase.td"
include "mlir/IR/PatternBase.td"

def SelectRewrite : Pass<"select-rewrite"> {
  // FIXME: add add summary/description
  let summary = "";
  let description = [{
  }];
  let dependentDialects = [

  ];
}

// Get either an IntegerAttr or DenseIntegerAtr of the same type as the input
def getMatchingOne : NativeCodeCall<"getMatchingOne($0)">;

// Rewrites arith.select %c, %t, %f to %c * %t + (1 - %c) * %f
def SelectRewritePattern : Pattern<
  (SelectOp $cond, $true_value, $false_value),
  [
    (Arith_ConstantOp:$one (getMatchingOne $cond)),
    (Arith_SubIOp:$not_cond $one, $cond, DefOverflow),
    (Arith_ExtUIOp:$ext_cond $cond, (returnType $true_value)),
    (Arith_MulIOp:$true_mul $ext_cond, $true_value, DefOverflow),
    (Arith_ExtUIOp:$ext_not_cond $not_cond, (returnType $false_value)),
    (Arith_MulIOp:$false_mul $ext_not_cond, $false_value, DefOverflow),
    (Arith_AddIOp $true_mul, $false_mul, DefOverflow)
  ]
>;


#endif  // LIB_TRANSFORMS_SelectRewrite_SelectRewrite_TD_

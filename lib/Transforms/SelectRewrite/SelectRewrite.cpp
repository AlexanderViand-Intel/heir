#include "lib/Transforms/SelectRewrite/SelectRewrite.h"

#include "mlir/include/mlir/Dialect/Arith/IR/Arith.h"  // from @llvm-project
#include "mlir/include/mlir/IR/TypeUtilities.h"        // from @llvm-project
#include "mlir/include/mlir/Transforms/GreedyPatternRewriteDriver.h"  // from @llvm-project
#include "mlir/include/mlir/Transforms/Passes.h"  // from @llvm-project

namespace mlir {
namespace heir {

#define GEN_PASS_DEF_SELECTREWRITE
#include "lib/Transforms/SelectRewrite/SelectRewrite.h.inc"

// currently only works for i1 or tensor<...xi1>
TypedAttr getMatchingOne(Value op) {
  auto intType = getElementTypeOrSelf(op);
  intType.dump();
  if (auto st = mlir::dyn_cast<ShapedType>(op.getType())) {
    auto containerType = st.cloneWith(st.getShape(), intType);
    containerType.dump();
    return DenseElementsAttr::get(containerType, true);
  }
  return IntegerAttr::get(intType, true);
}

namespace rewrites {
// In an inner namespace to avoid conflicts
#include "lib/Transforms/SelectRewrite/SelectRewrite.cpp.inc"
}  // namespace rewrites

struct SelectRewrite : impl::SelectRewriteBase<SelectRewrite> {
  using SelectRewriteBase::SelectRewriteBase;

  void runOnOperation() override {
    MLIRContext *context = &getContext();
    RewritePatternSet patterns(context);

    // popiulate TD patterns
    rewrites::populateWithGenerated(patterns);

    (void)applyPatternsAndFoldGreedily(getOperation(), std::move(patterns));
  }
};

}  // namespace heir
}  // namespace mlir

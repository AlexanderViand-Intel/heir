#include "lib/Conversion/PolynomialToPISA/PolynomialToPISA.h"

#include "lib/Conversion/Utils.h"
#include "lib/Dialect/ArithExt/IR/ArithExtDialect.h"
#include "lib/Dialect/PISA/IR/PISADialect.h"
#include "lib/Dialect/PISA/IR/PISAOps.h"
#include "mlir/include/mlir/Dialect/Polynomial/IR/PolynomialOps.h"  // from @llvm-project
#include "mlir/include/mlir/Transforms/DialectConversion.h"  // from @llvm-project

namespace mlir::heir {

#define GEN_PASS_DEF_POLYNOMIALTOPISA
#include "lib/Conversion/PolynomialToPISA/PolynomialToPISA.h.inc"

// Remove this class if no type conversions are necessary
class PolynomialToPISATypeConverter : public TypeConverter {
 public:
  PolynomialToPISATypeConverter(MLIRContext *ctx) {
    addConversion([](Type type) { return type; });
    // FIXME: implement, replace FooType with the type that needs
    // to be converted or remove this class
    // addConversion([ctx](FooType type) -> Type { return type; });
  }
};

struct ConvertAddOp : public OpConversionPattern<polynomial::AddOp> {
  ConvertAddOp(mlir::MLIRContext *context)
      : OpConversionPattern<polynomial::AddOp>(context) {}

  using OpConversionPattern::OpConversionPattern;

  LogicalResult matchAndRewrite(
      polynomial::AddOp op, polynomial::AddOpAdaptor adaptor,
      ConversionPatternRewriter &rewriter) const override {
    // FIXME: does not yet split poly with degree > 8k into multiple pisa ops
    auto q =
        rewriter.getI32IntegerAttr(42);  // FIXME: get q from polynomial type
    auto i = rewriter.getI32IntegerAttr(0);
    rewriter.replaceOpWithNewOp<pisa::AddOp>(op, adaptor.getLhs(),
                                             adaptor.getRhs(), q, i);
    return success();
  }
};

struct PolynomialToPISA : public impl::PolynomialToPISABase<PolynomialToPISA> {
  void runOnOperation() override {
    MLIRContext *context = &getContext();
    auto *module = getOperation();
    PolynomialToPISATypeConverter typeConverter(context);

    RewritePatternSet patterns(context);
    ConversionTarget target(*context);
    target.addLegalDialect<pisa::PISADialect>();
    target.addIllegalDialect<polynomial::PolynomialDialect>();
    target.addIllegalDialect<arith_ext::ArithExtDialect>();

    patterns.add<ConvertAddOp>(typeConverter, context);

    addStructuralConversionPatterns(typeConverter, patterns, target);

    // FIXME: This needs to be another OneToN Conversion, as a single polynomial
    // type (with degree >8k) will result in multiple "pisa polynomials"
    if (failed(applyPartialConversion(module, target, std::move(patterns)))) {
      return signalPassFailure();
    }
  }
};

}  // namespace mlir::heir

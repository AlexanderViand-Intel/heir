#ifndef LIB_DIALECT_LWE_CONVERSIONS_LWETOOPENFHE_LWETOOPENFHE_H_
#define LIB_DIALECT_LWE_CONVERSIONS_LWETOOPENFHE_LWETOOPENFHE_H_

#include "lib/Dialect/LWE/IR/LWEOps.h"
#include "lib/Dialect/Openfhe/IR/OpenfheOps.h"
#include "lib/Utils/ConversionUtils/ConversionUtils.h"
#include "mlir/include/mlir/Dialect/Func/IR/FuncOps.h"  // from @llvm-project
#include "mlir/include/mlir/IR/BuiltinAttributes.h"     // from @llvm-project
#include "mlir/include/mlir/IR/BuiltinTypes.h"          // from @llvm-project
#include "mlir/include/mlir/Pass/Pass.h"                // from @llvm-project
#include "mlir/include/mlir/Support/LLVM.h"             // from @llvm-project
#include "mlir/include/mlir/Support/LogicalResult.h"    // from @llvm-project
#include "mlir/include/mlir/Transforms/DialectConversion.h"  // from @llvm-project

namespace mlir::heir::lwe {

#define GEN_PASS_DECL
#include "lib/Dialect/LWE/Conversions/LWEToOpenfhe/LWEToOpenfhe.h.inc"

#define GEN_PASS_REGISTRATION
#include "lib/Dialect/LWE/Conversions/LWEToOpenfhe/LWEToOpenfhe.h.inc"

class ToOpenfheTypeConverter : public TypeConverter {
 public:
  ToOpenfheTypeConverter(MLIRContext *ctx);
};

FailureOr<Value> getContextualCryptoContext(Operation *op);

template <typename UnaryOp, typename OpenfheOp>
struct ConvertUnaryOp : public OpConversionPattern<UnaryOp> {
  using OpConversionPattern<UnaryOp>::OpConversionPattern;

  LogicalResult matchAndRewrite(
      UnaryOp op, typename UnaryOp::Adaptor adaptor,
      ConversionPatternRewriter &rewriter) const override {
    FailureOr<Value> result = getContextualCryptoContext(op.getOperation());
    if (failed(result)) return result;

    Value cryptoContext = result.value();
    rewriter.replaceOp(op, rewriter.create<OpenfheOp>(
                               op.getLoc(), cryptoContext, adaptor.getInput()));
    return success();
  }
};

template <typename BinOp, typename OpenfheOp>
struct ConvertBinOp : public OpConversionPattern<BinOp> {
  using OpConversionPattern<BinOp>::OpConversionPattern;

  LogicalResult matchAndRewrite(
      BinOp op, typename BinOp::Adaptor adaptor,
      ConversionPatternRewriter &rewriter) const override {
    FailureOr<Value> result = getContextualCryptoContext(op.getOperation());
    if (failed(result)) return result;

    Value cryptoContext = result.value();
    rewriter.replaceOpWithNewOp<OpenfheOp>(op, op.getOutput().getType(),
                                           cryptoContext, adaptor.getLhs(),
                                           adaptor.getRhs());
    return success();
  }
};

template <typename BinOp, typename OpenfheOp>
struct ConvertCiphertextPlaintextOp : public OpConversionPattern<BinOp> {
  using OpConversionPattern<BinOp>::OpConversionPattern;

  LogicalResult matchAndRewrite(
      BinOp op, typename BinOp::Adaptor adaptor,
      ConversionPatternRewriter &rewriter) const override {
    FailureOr<Value> result = getContextualCryptoContext(op.getOperation());
    if (failed(result)) return result;

    Value cryptoContext = result.value();
    rewriter.replaceOpWithNewOp<OpenfheOp>(
        op, op.getOutput().getType(), cryptoContext,
        adaptor.getCiphertextInput(), adaptor.getPlaintextInput());
    return success();
  }
};

template <typename RotateOp, typename OpenfheOp>
struct ConvertRotateOp : public OpConversionPattern<RotateOp> {
  ConvertRotateOp(mlir::MLIRContext *context)
      : OpConversionPattern<RotateOp>(context) {}

  using OpConversionPattern<RotateOp>::OpConversionPattern;

  LogicalResult matchAndRewrite(
      RotateOp op, typename RotateOp::Adaptor adaptor,
      ConversionPatternRewriter &rewriter) const override {
    FailureOr<Value> result = getContextualCryptoContext(op.getOperation());
    if (failed(result)) return result;

    Value cryptoContext = result.value();
    rewriter.replaceOp(op, rewriter.create<OpenfheOp>(
                               op.getLoc(), cryptoContext, adaptor.getInput(),
                               adaptor.getOffset()));
    return success();
  }
};

inline bool checkRelinToBasis(llvm::ArrayRef<int> toBasis) {
  if (toBasis.size() != 2) return false;
  return toBasis[0] == 0 && toBasis[1] == 1;
}

template <typename RelinOp, typename OpenfheOp>
struct ConvertRelinOp : public OpConversionPattern<RelinOp> {
  ConvertRelinOp(mlir::MLIRContext *context)
      : OpConversionPattern<RelinOp>(context) {}

  using OpConversionPattern<RelinOp>::OpConversionPattern;

  LogicalResult matchAndRewrite(
      RelinOp op, typename RelinOp::Adaptor adaptor,
      ConversionPatternRewriter &rewriter) const override {
    FailureOr<Value> result = getContextualCryptoContext(op.getOperation());
    if (failed(result)) return result;

    auto toBasis = adaptor.getToBasis();

    // Since the `Relinearize()` function in OpenFHE relinearizes a ciphertext
    // to the lowest level (for (1,s)), the `to_basis` of `<scheme>.RelinOp`
    // must be [0,1].
    if (!checkRelinToBasis(toBasis)) {
      op.emitError() << "toBasis must be [0, 1], got [" << toBasis << "]";
      return failure();
    }

    Value cryptoContext = result.value();
    rewriter.replaceOpWithNewOp<OpenfheOp>(op, op.getOutput().getType(),
                                           cryptoContext, adaptor.getInput());
    return success();
  }
};

}  // namespace mlir::heir::lwe

#endif  // LIB_DIALECT_LWE_CONVERSIONS_LWETOOPENFHE_LWETOOPENFHE_H_

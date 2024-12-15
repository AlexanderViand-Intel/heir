#include "lib/Dialect/LWE/Conversions/LWEToOpenfhe/LWEToOpenfhe.h"

#include <cassert>
#include <cstddef>
#include <cstdint>
#include <utility>

#include "lib/Dialect/LWE/IR/LWEAttributes.h"
#include "lib/Dialect/LWE/IR/LWEOps.h"
#include "lib/Dialect/LWE/IR/LWETypes.h"
#include "lib/Dialect/Openfhe/IR/OpenfheOps.h"
#include "lib/Dialect/Openfhe/IR/OpenfheTypes.h"
#include "lib/Utils/ConversionUtils/ConversionUtils.h"
#include "mlir/include/mlir/Dialect/Arith/IR/Arith.h"    // from @llvm-project
#include "mlir/include/mlir/Dialect/Tensor/IR/Tensor.h"  // from @llvm-project
#include "mlir/include/mlir/IR/BuiltinAttributes.h"      // from @llvm-project
#include "mlir/include/mlir/IR/BuiltinTypes.h"           // from @llvm-project
#include "mlir/include/mlir/IR/TypeUtilities.h"          // from @llvm-project
#include "mlir/include/mlir/IR/Visitors.h"               // from @llvm-project
#include "mlir/include/mlir/Support/LLVM.h"              // from @llvm-project
#include "mlir/include/mlir/Support/LogicalResult.h"     // from @llvm-project
#include "mlir/include/mlir/Transforms/DialectConversion.h"  // from @llvm-project

namespace mlir::heir::lwe {

ToOpenfheTypeConverter::ToOpenfheTypeConverter(MLIRContext *ctx) {
  addConversion([](Type type) { return type; });
  addConversion([ctx](lwe::RLWEPublicKeyType type) -> Type {
    return openfhe::PublicKeyType::get(ctx);
  });
  addConversion([ctx](lwe::RLWESecretKeyType type) -> Type {
    return openfhe::PrivateKeyType::get(ctx);
  });
}

FailureOr<Value> getContextualCryptoContext(Operation *op) {
  auto result = getContextualArgFromFunc<openfhe::CryptoContextType>(op);
  if (failed(result)) {
    return op->emitOpError()
           << "Found LWE op in a function without a public key argument."
              " Did the AddCryptoContextArg pattern fail to run?";
  }
  return result.value();
}

LogicalResult ConvertEncryptOp::matchAndRewrite(
    lwe::RLWEEncryptOp op, OpAdaptor adaptor,
    ConversionPatternRewriter &rewriter) const {
  FailureOr<Value> result = getContextualCryptoContext(op.getOperation());
  if (failed(result)) return result;

  auto keyType = dyn_cast<lwe::RLWEPublicKeyType>(op.getKey().getType());
  if (!keyType)
    return op.emitError()
           << "OpenFHE only supports public key encryption for LWE.";

  Value cryptoContext = result.value();
  rewriter.replaceOp(op,
                     rewriter.create<openfhe::EncryptOp>(
                         op.getLoc(), op.getOutput().getType(), cryptoContext,
                         adaptor.getInput(), adaptor.getKey()));
  return success();
}

LogicalResult ConvertDecryptOp::matchAndRewrite(
    lwe::RLWEDecryptOp op, OpAdaptor adaptor,
    ConversionPatternRewriter &rewriter) const {
  FailureOr<Value> result = getContextualCryptoContext(op.getOperation());
  if (failed(result)) return result;

  Value cryptoContext = result.value();
  rewriter.replaceOp(op,
                     rewriter.create<openfhe::DecryptOp>(
                         op.getLoc(), op.getOutput().getType(), cryptoContext,
                         adaptor.getInput(), adaptor.getSecretKey()));
  return success();
}

// OpenFHE has a convention that all inputs to MakePackedPlaintext are
// std::vector<int64_t>, so we need to cast the input to that type.
LogicalResult ConvertEncodeOp::matchAndRewrite(
    lwe::RLWEEncodeOp op, OpAdaptor adaptor,
    ConversionPatternRewriter &rewriter) const {
  FailureOr<Value> result = getContextualCryptoContext(op.getOperation());
  if (failed(result)) return result;
  Value cryptoContext = result.value();

  Value input = adaptor.getInput();
  auto elementTy = getElementTypeOrSelf(input.getType());

  auto tensorTy = mlir::dyn_cast<RankedTensorType>(input.getType());
  // Replicate scalar inputs into a splat tensor with shape matching
  // the ring dimension.
  if (!tensorTy) {
    auto ringDegree =
        op.getRing().getPolynomialModulus().getPolynomial().getDegree();
    tensor::SplatOp splat = rewriter.create<tensor::SplatOp>(
        op.getLoc(), RankedTensorType::get({ringDegree}, elementTy), input);
    input = splat.getResult();
    tensorTy = splat.getType();
  }

  // Cast inputs to the correct types for OpenFHE API.
  if (auto intTy = mlir::dyn_cast<IntegerType>(elementTy)) {
    if (intTy.getWidth() > 64)
      return op.emitError() << "No supported packing technique for integers "
                               "bigger than 64 bits.";

    if (intTy.getWidth() < 64) {
      // OpenFHE has a convention that all inputs to MakePackedPlaintext are
      // std::vector<int64_t>, so we need to cast the input to that type.
      auto int64Ty = rewriter.getIntegerType(64);
      auto newTensorTy = RankedTensorType::get(tensorTy.getShape(), int64Ty);
      input = rewriter.create<arith::ExtSIOp>(op.getLoc(), newTensorTy, input);
    }
  } else {
    auto floatTy = cast<FloatType>(elementTy);
    if (floatTy.getWidth() > 64)
      return op.emitError() << "No supported packing technique for floats "
                               "bigger than 64 bits.";

    if (floatTy.getWidth() < 64) {
      // OpenFHE has a convention that all inputs to MakeCKKSPackedPlaintext are
      // std::vector<double>, so we need to cast the input to that type.
      auto f64Ty = rewriter.getF64Type();
      auto newTensorTy = RankedTensorType::get(tensorTy.getShape(), f64Ty);
      input = rewriter.create<arith::ExtFOp>(op.getLoc(), newTensorTy, input);
    }
  }

  lwe::RLWEPlaintextType plaintextType =
      lwe::RLWEPlaintextType::get(op.getContext(), op.getEncoding(),
                                  op.getRing(), adaptor.getInput().getType());

  if (isa<lwe::InverseCanonicalEmbeddingEncodingAttr>(op.getEncoding())) {
    rewriter.replaceOpWithNewOp<openfhe::MakeCKKSPackedPlaintextOp>(
        op, plaintextType, cryptoContext, input);
    return success();
  }
  if (isa<lwe::CoefficientEncodingAttr>(op.getEncoding())) {
    // TODO (#1192): support coefficient packing in `--lwe-to-openfhe`
    op.emitError() << "HEIR does not yet support coefficient encoding "
                      " when targeting OpenFHE";
    return failure();
  }
  if (isa<lwe::PolynomialEvaluationEncodingAttr>(op.getEncoding())) {
    rewriter.replaceOpWithNewOp<openfhe::MakePackedPlaintextOp>(
        op, plaintextType, cryptoContext, input);

    return success();
  }
  // else: encoding isn't support explicitly:
  op.emitError(
      "Unexpected encoding while targeting OpenFHE. "
      "If you expect this type of encoding to be supported "
      "for the OpenFHE backend, please file a bug report.");
  return failure();
}

}  // namespace mlir::heir::lwe

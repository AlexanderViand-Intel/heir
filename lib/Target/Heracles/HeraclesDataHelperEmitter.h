#ifndef LIB_TARGET_HERACLES_HERACLESDATEHELPEREMITTER_H_
#define LIB_TARGET_HERACLES_HERACLESDATEHELPEREMITTER_H_

#include "lib/Analysis/SelectVariableNames/SelectVariableNames.h"
#include "lib/Dialect/BGV/IR/BGVOps.h"
#include "lib/Dialect/CKKS/IR/CKKSOps.h"
#include "lib/Dialect/LWE/IR/LWEOps.h"
#include "lib/Dialect/Openfhe/IR/OpenfheOps.h"
#include "lib/Target/Heracles/HeraclesUtils.h"
#include "lib/Target/OpenFhePke/OpenFheUtils.h"
#include "llvm/include/llvm/Support/raw_ostream.h"       // from @llvm-project
#include "mlir/include/mlir/Dialect/Arith/IR/Arith.h"    // from @llvm-project
#include "mlir/include/mlir/Dialect/Func/IR/FuncOps.h"   // from @llvm-project
#include "mlir/include/mlir/Dialect/Tensor/IR/Tensor.h"  // from @llvm-project
#include "mlir/include/mlir/IR/BuiltinOps.h"             // from @llvm-project
#include "mlir/include/mlir/Support/IndentedOstream.h"   // from @llvm-project
#include "mlir/include/mlir/Support/LogicalResult.h"     // from @llvm-project

namespace mlir {
namespace heir {
namespace heracles {

void registerToHeraclesDataHelperTranslation();
void registerHeraclesDataHelperTranslateOptions();

/// Emits C++ code similar to the OpenFHEPke emitter,
// but augmented to serialize the ctxts to HERACLES data format (using protobuf)
LogicalResult translateToHeraclesDataHelper(
    Operation *op, llvm::raw_ostream &os,
    const openfhe::OpenfheImportType &importType);

class HeraclesSDKDataHelperEmitter {
 public:
  HeraclesSDKDataHelperEmitter(raw_ostream &os,
                               SelectVariableNames *variableNames,
                               const openfhe::OpenfheImportType &importType);

  LogicalResult translate(::mlir::Operation &operation);

 private:
  /// Output stream to emit to
  raw_indented_ostream os;

  /// Import Type
  openfhe::OpenfheImportType importType_;

  /// Pre-populated analysis selecting unique variable names for all the SSA
  /// values.
  SelectVariableNames *variableNames;

  // Functions for emitting individual ops
  LogicalResult printOperation(::mlir::ModuleOp op);
  LogicalResult printOperation(::mlir::func::FuncOp op);
  LogicalResult printOperation(::mlir::func::CallOp op);
  LogicalResult printOperation(::mlir::func::ReturnOp op);
  LogicalResult printOperation(::mlir::arith::ConstantOp op);
  LogicalResult printOperation(arith::ExtFOp op);
  LogicalResult printOperation(arith::ExtSIOp op);
  LogicalResult printOperation(arith::IndexCastOp op);

  LogicalResult printOperation(lwe::RLWEDecodeOp op);
  LogicalResult printOperation(lwe::ReinterpretUnderlyingTypeOp op);

  LogicalResult printOperation(openfhe::DecryptOp op);
  LogicalResult printOperation(openfhe::EncryptOp op);
  LogicalResult printOperation(openfhe::GenParamsOp op);
  LogicalResult printOperation(openfhe::GenContextOp op);
  LogicalResult printOperation(openfhe::GenMulKeyOp op);
  LogicalResult printOperation(openfhe::GenRotKeyOp op);
  LogicalResult printOperation(openfhe::GenBootstrapKeyOp op);
  LogicalResult printOperation(openfhe::SetupBootstrapOp op);
  LogicalResult printOperation(openfhe::MakePackedPlaintextOp op);
  LogicalResult printOperation(openfhe::MakeCKKSPackedPlaintextOp op);
  LogicalResult printOperation(tensor::ExtractOp op);
  LogicalResult printOperation(tensor::InsertOp op);
  LogicalResult printOperation(tensor::SplatOp op);
  LogicalResult printOperation(tensor::EmptyOp op);

  // Helpers for above
  LogicalResult emitType(Type type, Location loc);
  LogicalResult emitTypedAssignPrefix(Value result, Location loc);
  void emitAutoAssignPrefix(Value result);
  StringRef canonicalizeDebugPort(StringRef debugPortName);
};

}  // namespace heracles
}  // namespace heir
}  // namespace mlir
#endif  // LIB_TARGET_HERACLES_HERACLESDATEHELPEREMITTER_H_

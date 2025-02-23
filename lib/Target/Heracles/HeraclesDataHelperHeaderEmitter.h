#ifndef LIB_TARGET_HERACLES_HERACLESDATEHELPERHEADEREMITTER_H_
#define LIB_TARGET_HERACLES_HERACLESDATEHELPERHEADEREMITTER_H_

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

void registerToHeraclesDataHelperHeaderTranslation();

LogicalResult translateToHeraclesDataHelperHeader(
    Operation *op, llvm::raw_ostream &os,
    const openfhe::OpenfheImportType &importType);

class HeraclesDataHelperHeaderEmitter {
 public:
  HeraclesDataHelperHeaderEmitter(raw_ostream &os,
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

  LogicalResult printOperation(::mlir::ModuleOp op);
  LogicalResult printOperation(::mlir::func::FuncOp op);

  // Helper for above
  LogicalResult emitType(Type type, Location loc);
};

}  // namespace heracles
}  // namespace heir
}  // namespace mlir
#endif  // LIB_TARGET_HERACLES_HERACLESDATEHELPERHEADEREMITTER_H_

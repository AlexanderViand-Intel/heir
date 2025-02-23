#ifndef LIB_TARGET_HERACLES_HERACLESPYBINDEMITTER_H
#define LIB_TARGET_HERACLES_HERACLESPYBINDEMITTER_H
#include <string>

#include "lib/Target/OpenFhePke/OpenFhePkeTemplates.h"
#include "llvm/include/llvm/Support/raw_ostream.h"      // from @llvm-project
#include "mlir/include/mlir/Dialect/Func/IR/FuncOps.h"  // from @llvm-project
#include "mlir/include/mlir/IR/BuiltinOps.h"            // from @llvm-project
#include "mlir/include/mlir/IR/Operation.h"             // from @llvm-project
#include "mlir/include/mlir/IR/Value.h"                 // from @llvm-project
#include "mlir/include/mlir/Support/IndentedOstream.h"  // from @llvm-project
#include "mlir/include/mlir/Support/LLVM.h"             // from @llvm-project
#include "mlir/include/mlir/Support/LogicalResult.h"    // from @llvm-project
namespace mlir {
namespace heir {
namespace heracles {

void registerToHeraclesPybindTranslation();

::mlir::LogicalResult translateToHeraclesPybind(
    ::mlir::Operation *op, llvm::raw_ostream &os,
    const std::string &headerInclude, const std::string &pythonModuleName);

/// For each function in the mlir module, emits a function pybind declaration
/// along with any necessary includes.
class HeraclesPybindEmitter {
 public:
  HeraclesPybindEmitter(raw_ostream &os, const std::string &headerInclude,
                        const std::string &pythonModuleName)
      : headerInclude_(headerInclude),
        pythonModuleName_(pythonModuleName),
        os(os) {}

  LogicalResult translate(::mlir::Operation &operation);

 private:
  const std::string headerInclude_;
  const std::string pythonModuleName_;

  /// Output stream to emit to.
  raw_indented_ostream os;

  // Functions for printing individual ops
  LogicalResult printOperation(::mlir::ModuleOp op);
  LogicalResult printOperation(::mlir::func::FuncOp op);
};
}  // namespace heracles
}  // namespace heir
}  // namespace mlir
#endif  // LIB_TARGET_HERACLES_HERACLESPYBINDEMITTER_H

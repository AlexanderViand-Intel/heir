#include "lib/Target/Heracles/HeraclesPybindEmitter.h"

#include "lib/Analysis/SelectVariableNames/SelectVariableNames.h"
#include "lib/Dialect/BGV/IR/BGVDialect.h"
#include "lib/Dialect/CKKS/IR/CKKSDialect.h"
#include "lib/Dialect/LWE/IR/LWEDialect.h"
#include "lib/Dialect/ModArith/IR/ModArithDialect.h"
#include "lib/Dialect/ModuleAttributes.h"
#include "lib/Dialect/Openfhe/IR/OpenfheDialect.h"
#include "lib/Dialect/Polynomial/IR/PolynomialDialect.h"
#include "lib/Dialect/RNS/IR/RNSDialect.h"
#include "lib/Dialect/RNS/IR/RNSTypes.h"
#include "lib/Target/OpenFhePke/OpenFhePkeTemplates.h"
#include "lib/Target/OpenFhePke/OpenFheUtils.h"
#include "lib/Utils/TargetUtils.h"
#include "llvm/include/llvm/Support/CommandLine.h"       // from @llvm-project
#include "llvm/include/llvm/Support/Debug.h"             // from @llvm-project
#include "llvm/include/llvm/Support/FormatVariadic.h"    // from @llvm-project
#include "llvm/include/llvm/Support/raw_ostream.h"       // from @llvm-project
#include "mlir/include/mlir/Dialect/Arith/IR/Arith.h"    // from @llvm-project
#include "mlir/include/mlir/Dialect/Func/IR/FuncOps.h"   // from @llvm-project
#include "mlir/include/mlir/Dialect/Tensor/IR/Tensor.h"  // from @llvm-project
#include "mlir/include/mlir/IR/DialectRegistry.h"        // from @llvm-project
#include "mlir/include/mlir/IR/Operation.h"              // from @llvm-project
#include "mlir/include/mlir/IR/Value.h"                  // from @llvm-project
#include "mlir/include/mlir/Support/LLVM.h"              // from @llvm-project
#include "mlir/include/mlir/Tools/mlir-translate/Translation.h"  // from @llvm-project

#define DEBUG_TYPE "HeraclesPybindEmitter"

namespace mlir {
namespace heir {
namespace heracles {

using openfhe::kPybindCommon;
using openfhe::kPybindFunctionTemplate;
using openfhe::kPybindImports;
using openfhe::kPybindModuleTemplate;
using openfhe::pybindOptions;

void registerToHeraclesPybindTranslation() {
  TranslateFromMLIRRegistration reg(
      "emit-heracles-pybind",
      "Emit a C++ file containing pybind11 bindings for the input openfhe "
      "dialect IR"
      "--emit-heracles-pybind",
      [](Operation *op, llvm::raw_ostream &output) {
        return translateToHeraclesPybind(op, output,
                                         pybindOptions->pybindHeaderInclude,
                                         pybindOptions->pybindModuleName);
      },
      [](DialectRegistry &registry) {
        registry.insert<arith::ArithDialect, func::FuncDialect,
                        tensor::TensorDialect, openfhe::OpenfheDialect,
                        lwe::LWEDialect,
                        ::mlir::heir::polynomial::PolynomialDialect,
                        mod_arith::ModArithDialect, rns::RNSDialect>();
        rns::registerExternalRNSTypeInterfaces(registry);
      });
}

LogicalResult translateToHeraclesPybind(Operation *op, llvm::raw_ostream &os,
                                        const std::string &headerInclude,
                                        const std::string &pythonModuleName) {
  HeraclesPybindEmitter emitter(os, headerInclude, pythonModuleName);
  return emitter.translate(*op);
}

LogicalResult HeraclesPybindEmitter::translate(Operation &op) {
  LogicalResult status =
      llvm::TypeSwitch<Operation &, LogicalResult>(op)
          .Case<ModuleOp>([&](auto op) { return printOperation(op); })
          .Case<func::FuncOp>([&](auto op) { return printOperation(op); })
          .Default([&](Operation &) {
            return op.emitOpError("unable to find printer for op");
          });

  if (failed(status)) {
    op.emitOpError(llvm::formatv("Failed to translate op {0}", op.getName()));
    return failure();
  }
  return success();
}

LogicalResult HeraclesPybindEmitter::printOperation(ModuleOp moduleOp) {
  os << kPybindImports << "\n";
  os << "#include \"" << headerInclude_ << "\"\n";
  os << kPybindCommon << "\n";

  os << llvm::formatv(kPybindModuleTemplate.data(), pythonModuleName_) << "\n";
  os.indent();

  for (Operation &op : moduleOp) {
    if (failed(translate(op))) {
      return failure();
    }
  }

  os.unindent();
  os << "}\n";
  return success();
}

LogicalResult HeraclesPybindEmitter::printOperation(func::FuncOp funcOp) {
  // If function name does not contain `__`, skip it
  if (funcOp.getName().str().find("__") == std::string::npos) {
    LLVM_DEBUG(emitWarning(funcOp.getLoc(),
                           "Skipping function " + funcOp.getName().str() +
                               " without double underscore in name."););
    return success();
  }

  os << llvm::formatv(kPybindFunctionTemplate.data(), funcOp.getName()) << "\n";
  return success();
}

}  // namespace heracles
}  // namespace heir
}  // namespace mlir

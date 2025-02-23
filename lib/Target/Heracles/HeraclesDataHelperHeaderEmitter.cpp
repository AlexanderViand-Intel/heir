#include "lib/Target/Heracles/HeraclesDataHelperHeaderEmitter.h"

#include "lib/Analysis/SelectVariableNames/SelectVariableNames.h"
#include "lib/Dialect/BGV/IR/BGVDialect.h"
#include "lib/Dialect/CKKS/IR/CKKSDialect.h"
#include "lib/Dialect/LWE/IR/LWEDialect.h"
#include "lib/Dialect/ModArith/IR/ModArithDialect.h"
#include "lib/Dialect/ModuleAttributes.h"
#include "lib/Dialect/Polynomial/IR/PolynomialDialect.h"
#include "lib/Dialect/RNS/IR/RNSDialect.h"
#include "lib/Dialect/RNS/IR/RNSTypes.h"
#include "lib/Target/OpenFhePke/OpenFheUtils.h"
#include "lib/Utils/TargetUtils.h"
#include "llvm/include/llvm/ADT/TypeSwitch.h"           // from @llvm-project
#include "llvm/include/llvm/Support/Debug.h"            // from @llvm-project
#include "llvm/include/llvm/Support/FormatVariadic.h"   // from @llvm-project
#include "mlir/include/mlir/Dialect/Arith/IR/Arith.h"   // from @llvm-project
#include "mlir/include/mlir/Dialect/Func/IR/FuncOps.h"  // from @llvm-project
#include "mlir/include/mlir/Support/LLVM.h"             // from @llvm-project
#include "mlir/include/mlir/Tools/mlir-translate/Translation.h"  // from @llvm-project

namespace mlir {
namespace heir {
namespace heracles {

using openfhe::convertType;
using openfhe::OpenfheImportType;
using openfhe::OpenfheScheme;
using openfhe::options;

void registerToHeraclesDataHelperHeaderTranslation() {
  TranslateFromMLIRRegistration reg(
      "emit-heracles-data-helper-header",
      "emits header for helper that handles encode/encypt decode/decrypt",
      [](Operation *op, llvm::raw_ostream &output) {
        return translateToHeraclesDataHelperHeader(op, output,
                                                   options->openfheImportType);
      },
      [](DialectRegistry &registry) {
        registry.insert<arith::ArithDialect, func::FuncDialect,
                        tensor::TensorDialect, polynomial::PolynomialDialect,
                        openfhe::OpenfheDialect, lwe::LWEDialect,
                        ckks::CKKSDialect, bgv::BGVDialect,
                        mod_arith::ModArithDialect, rns::RNSDialect>();
        rns::registerExternalRNSTypeInterfaces(registry);
      });
}

LogicalResult translateToHeraclesDataHelperHeader(
    Operation *op, llvm::raw_ostream &os, const OpenfheImportType &importType) {
  SelectVariableNames variableNames(op);
  HeraclesDataHelperHeaderEmitter emitter(os, &variableNames, importType);
  return emitter.translate(*op);
}

LogicalResult HeraclesDataHelperHeaderEmitter::translate(Operation &op) {
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

LogicalResult HeraclesDataHelperHeaderEmitter::printOperation(
    ModuleOp moduleOp) {
  OpenfheScheme scheme;
  if (moduleOp->getAttr(kBGVSchemeAttrName)) {
    scheme = OpenfheScheme::BGV;
  } else if (moduleOp->getAttr(kCKKSSchemeAttrName)) {
    scheme = OpenfheScheme::CKKS;
  } else {
    return emitError(moduleOp.getLoc(), "Missing scheme attribute on module");
  }

  os << getModulePrelude(scheme, importType_) << "\n";
  for (Operation &op : moduleOp) {
    if (failed(translate(op))) {
      return failure();
    }
  }
  return success();
}

LogicalResult HeraclesDataHelperHeaderEmitter::printOperation(
    func::FuncOp funcOp) {
  // If keeping this consistent alongside the non-header emitter gets annoying,
  // extract to a shared function in a base class.
  if (funcOp.getNumResults() > 1) {
    emitWarning(
        funcOp->getLoc(),
        llvm::formatv("Only functions with a single return type "
                      "are supported, but function {0} has {1}, skipping.",
                      funcOp.getName(), funcOp.getNumResults()));
    return success();
  }

  Type result = funcOp.getResultTypes()[0];
  if (failed(emitType(result, funcOp->getLoc()))) {
    return funcOp.emitOpError() << "Failed to emit type " << result;
  }

  os << " " << funcOp.getName() << "(";

  for (Value arg : funcOp.getArguments()) {
    if (failed(convertType(arg.getType(), arg.getLoc()))) {
      return funcOp.emitOpError() << "Failed to emit type " << arg.getType();
    }
  }

  os << commaSeparatedValues(funcOp.getArguments(), [&](Value value) {
    auto res = convertType(value.getType(), funcOp->getLoc());
    return res.value() + " " + variableNames->getNameForValue(value);
  });
  os << ");\n";

  return success();
}

LogicalResult HeraclesDataHelperHeaderEmitter::emitType(Type type,
                                                        Location loc) {
  auto result = convertType(type, loc);
  if (failed(result)) {
    return failure();
  }
  os << result;
  return success();
}

HeraclesDataHelperHeaderEmitter::HeraclesDataHelperHeaderEmitter(
    raw_ostream &os, SelectVariableNames *variableNames,
    const OpenfheImportType &importType)
    : os(os), importType_(importType), variableNames(variableNames) {}

}  // namespace heracles
}  // namespace heir
}  // namespace mlir

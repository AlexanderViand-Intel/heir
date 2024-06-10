#include "lib/Target/PISA/PISAEmitter.h"

#include "lib/Analysis/SelectVariableNames/SelectVariableNames.h"
#include "lib/Dialect/PISA/IR/PISAOps.h"
#include "lib/Target/Utils.h"
#include "llvm/include/llvm/ADT/TypeSwitch.h"            // from @llvm-project
#include "llvm/include/llvm/Support/FormatVariadic.h"    // from @llvm-project
#include "mlir/include/mlir/Dialect/Arith/IR/Arith.h"    // from @llvm-project
#include "mlir/include/mlir/Dialect/Func/IR/FuncOps.h"   // from @llvm-project
#include "mlir/include/mlir/Dialect/Tensor/IR/Tensor.h"  // from @llvm-project
#include "mlir/include/mlir/Support/LLVM.h"              // from @llvm-project
#include "mlir/include/mlir/Tools/mlir-translate/Translation.h"  // from @llvm-project

namespace mlir {
namespace heir {
namespace pisa {

void registerToPISATranslation() {
  TranslateFromMLIRRegistration reg(
      "emit-pisa", "translate the pisa dialect to textual pISA representation",
      [](Operation *op, llvm::raw_ostream &output) {
        return translateToPISA(op, output);
      },
      [](DialectRegistry &registry) {
        registry.insert<arith::ArithDialect, func::FuncDialect,
                        tensor::TensorDialect, pisa::PISADialect>();
      });
}

LogicalResult translateToPISA(Operation *op, llvm::raw_ostream &os) {
  SelectVariableNames variableNames(op);
  PISAEmitter emitter(os, &variableNames);
  LogicalResult result = emitter.translate(*op);
  return result;
}

LogicalResult PISAEmitter::translate(::mlir::Operation &op) {
  LogicalResult status =
      llvm::TypeSwitch<Operation &, LogicalResult>(op)
          // Builtin ops
          .Case<ModuleOp>([&](auto op) { return printOperation(op); })
          // Func ops
          .Case<func::FuncOp, func::ReturnOp>(
              [&](auto op) { return printOperation(op); })
          // Arith ops
          .Case<arith::ConstantOp>([&](auto op) { return printOperation(op); })
          // PISA Ops
          .Case<AddOp, SubOp, MulOp, MuliOp, MacOp, MaciOp, NTTOp, INTTOp>(
              [&](auto op) { return printOperation(op); })
          .Default([&](Operation &) {
            return op.emitOpError("unable to find printer for op");
          });

  if (failed(status)) {
    op.emitOpError(llvm::formatv("Failed to translate op {0}", op.getName()));
    return failure();
  }
  return success();
}

LogicalResult PISAEmitter::printOperation(ModuleOp moduleOp) {
  // TODO: In the future, consider starting new files/ streams for each module?
  for (Operation &op : moduleOp) {
    if (failed(translate(op))) {
      return failure();
    }
  }
  return success();
}

LogicalResult PISAEmitter::printOperation(func::FuncOp funcOp) {
  // TODO: How to deal with multiple functions?
  // TODO: map the arguments to inputs (outputs will be done in return)
  for (Block &block : funcOp.getBlocks()) {
    for (Operation &op : block.getOperations()) {
      if (failed(translate(op))) {
        return failure();
      }
    }
  }
  return success();
}

LogicalResult PISAEmitter::printOperation(func::ReturnOp op) {
  // TODO: need to map the yielded values to the outputs
  return success();
}

LogicalResult PISAEmitter::printOperation(arith::ConstantOp op) {
  // TODO: How to properly deal with constants/immediates in PISA?
  return failure();
}

LogicalResult PISAEmitter::printOperation(AddOp op) {
  return printPISAOp("padd", op.getResult(), {op.getLhs(), op.getRhs()},
                     op.getI());
}

LogicalResult PISAEmitter::printOperation(SubOp op) {
  return printPISAOp("psub", op.getResult(), {op.getLhs(), op.getRhs()},
                     op.getI());
}

LogicalResult PISAEmitter::printOperation(MulOp op) {
  return printPISAOp("pmul", op.getResult(), {op.getLhs(), op.getRhs()},
                     op.getI());
}

LogicalResult PISAEmitter::printOperation(MuliOp op) {
  return failure();  // TODO: how to print immediate values?
                     // SDK makes it seem like they are also in input json?
}

LogicalResult PISAEmitter::printOperation(MacOp op) {
  return printPISAOp("pmac", op.getResult(),
                     {op.getLhs(), op.getRhs(), op.getAcc()}, op.getI());
}

LogicalResult PISAEmitter::printOperation(MaciOp op) {
  return failure();  // TODO: how to print immediate values?
                     // SDK makes it seem like they are also in input json?
}

LogicalResult PISAEmitter::printOperation(NTTOp op) {
  return failure();  // TODO: how to handle twiddle values?
                     // SDK makes it seem like they are also in input json?
}

LogicalResult PISAEmitter::printOperation(INTTOp op) {
  return failure();  // TODO: how to handle twiddle values?
                     // SDK makes it seem like they are also in input json?
}

LogicalResult PISAEmitter::printPISAOp(std::string_view name, Value result,
                                       ValueRange operands, int index) {
  os << "13, " << name << ", " << variableNames->getNameForValue(result)
     << ", ";
  os << commaSeparatedValues(operands, [&](Value value) {
    return variableNames->getNameForValue(value);
  });
  os << ", " << index << "\n";
  return success();
}

PISAEmitter::PISAEmitter(raw_ostream &os, SelectVariableNames *variableNames)
    : os(os), variableNames(variableNames) {}

}  // namespace pisa
}  // namespace heir
}  // namespace mlir

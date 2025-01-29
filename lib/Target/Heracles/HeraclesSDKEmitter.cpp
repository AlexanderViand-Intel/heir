#include "lib/Target/Heracles/HeraclesSDKEmitter.h"

#include "lib/Analysis/SelectVariableNames/SelectVariableNames.h"
#include "lib/Dialect/BGV/IR/BGVDialect.h"
#include "lib/Dialect/BGV/IR/BGVOps.h"
#include "lib/Dialect/CKKS/IR/CKKSDialect.h"
#include "lib/Dialect/CKKS/IR/CKKSOps.h"
#include "lib/Dialect/LWE/IR/LWEDialect.h"
#include "lib/Dialect/LWE/IR/LWEOps.h"
#include "lib/Dialect/LWE/IR/LWETypes.h"
#include "lib/Dialect/ModArith/IR/ModArithDialect.h"
#include "lib/Dialect/RNS/IR/RNSDialect.h"
#include "lib/Dialect/RNS/IR/RNSTypes.h"
#include "lib/Utils/TargetUtils.h"
#include "llvm/include/llvm/ADT/TypeSwitch.h"            // from @llvm-project
#include "llvm/include/llvm/Support/FormatVariadic.h"    // from @llvm-project
#include "mlir/include/mlir/Dialect/Arith/IR/Arith.h"    // from @llvm-project
#include "mlir/include/mlir/Dialect/Func/IR/FuncOps.h"   // from @llvm-project
#include "mlir/include/mlir/Dialect/Tensor/IR/Tensor.h"  // from @llvm-project
#include "mlir/include/mlir/Support/LLVM.h"              // from @llvm-project
#include "mlir/include/mlir/Tools/mlir-translate/Translation.h"  // from @llvm-project

namespace mlir {
namespace heir {
namespace heracles {

void registerToHeraclesSDKTranslation() {
  TranslateFromMLIRRegistration reg(
      "emit-heracles-sdk",
      "translate bgv or ckks dialect to textual Heracles SDK representation",
      [](Operation *op, llvm::raw_ostream &output) {
        return translateToHeraclesBGV(op, output, false);
      },
      [](DialectRegistry &registry) {
        registry.insert<arith::ArithDialect, func::FuncDialect,
                        tensor::TensorDialect, bgv::BGVDialect,
                        ckks::CKKSDialect, lwe::LWEDialect,
                        mod_arith::ModArithDialect, rns::RNSDialect>();
        rns::registerExternalRNSTypeInterfaces(registry);
      });
}

// // FIXME: defining inputs?
// void registerToHeraclesBGVInputsTranslation() {
//   TranslateFromMLIRRegistration reg(
//       "emit-heracles-bgv-inputs",
//       "translate the bgv dialect to its textual Heracles SDK representation,
//       " "producing the inputs file ",
//       [](Operation *op, llvm::raw_ostream &output) {
//         return translateToHeraclesBGV(op, output, true);
//       },
//       [](DialectRegistry &registry) {
//         registry.insert<arith::ArithDialect, func::FuncDialect,
//                         tensor::TensorDialect, bgv::BGVDialect,
//                         lwe::LWEDialect, mod_arith::ModArithDialect,
//                         rns::RNSDialect>();
//         rns::registerExternalRNSTypeInterfaces(registry);
//       });
// }

LogicalResult translateToHeraclesBGV(Operation *op, llvm::raw_ostream &os,
                                     bool emitInputOnly) {
  SelectVariableNames variableNames(op, false);
  HeraclesSDKEmitter emitter(os, &variableNames, emitInputOnly);
  LogicalResult result = emitter.translate(*op);
  return result;
}

LogicalResult HeraclesSDKEmitter::translate(::mlir::Operation &op) {
  LogicalResult status =
      llvm::TypeSwitch<Operation &, LogicalResult>(op)
          // Builtin ops
          .Case<ModuleOp>([&](auto op) { return printOperation(op); })
          // Func ops
          .Case<func::FuncOp, func::ReturnOp>(
              [&](auto op) { return printOperation(op); })
          // Arith ops
          .Case<arith::ConstantOp>([&](auto op) { return printOperation(op); })
          // LWE Ops
          .Case<lwe::RLWEEncodeOp, lwe::RLWEDecodeOp, lwe::RLWEEncryptOp,
                lwe::RLWEDecryptOp>([&](auto op) { return printOperation(op); })
          // BGV Ops
          .Case<bgv::AddOp, bgv::AddPlainOp, bgv::SubOp, bgv::SubPlainOp,
                bgv::MulOp, bgv::MulPlainOp, bgv::NegateOp, bgv::RelinearizeOp,
                bgv::RotateOp, bgv::ModulusSwitchOp, bgv::ExtractOp>(
              [&](auto op) { return printOperation(op); })
          // CKKS Ops
          .Case<ckks::AddOp, ckks::AddPlainOp, ckks::SubOp, ckks::SubPlainOp,
                ckks::MulOp, ckks::MulPlainOp, ckks::NegateOp,
                ckks::RelinearizeOp, ckks::RotateOp, ckks::RescaleOp,
                ckks::ExtractOp>([&](auto op) { return printOperation(op); })
          .Default([&](Operation &) {
            return op.emitOpError("unable to find printer for op");
          });

  if (failed(status)) {
    op.emitOpError(llvm::formatv("Failed to translate op {0}", op.getName()));
    return failure();
  }
  return success();
}

LogicalResult HeraclesSDKEmitter::printOperation(ModuleOp moduleOp) {
  // Emit (required) header
  os << "instruction,scheme,poly_modulus_degree,rns_terms,"
        "arg0,arg1,arg2,arg3,"
        "arg4,arg5,arg6,arg7,arg8,arg9"
     << "\n";

  // Emit function body/bodies
  int funcs = 0;
  for (Operation &op : moduleOp) {
    if (!llvm::isa<func::FuncOp>(op)) {
      emitError(op.getLoc(),
                "Heracles BGV emitter only supports code wrapped in functions. "
                "Operation will not be translated.");
      continue;
    }
    if (++funcs > 1)
      emitWarning(op.getLoc(),
                  "Heracles BGV emitter is designed for single functions. "
                  "Inputs, outputs and bodies of different functions "
                  "will be merged.");
    if (failed(translate(op))) {
      return failure();
    }
  }
  return success();
}

LogicalResult HeraclesSDKEmitter::printOperation(func::FuncOp funcOp) {
  if (emitInputOnly) {
    // FIXME: Implement
    assert(false && "Not implemented yet");
    return success();
  }

  for (Block &block : funcOp.getBlocks()) {
    for (Operation &op : block.getOperations()) {
      if (failed(translate(op))) {
        return failure();
      }
    }
  }
  return success();
}

LogicalResult HeraclesSDKEmitter::printOperation(func::ReturnOp op) {
  // FIXME: need to map returned/yielded values to outputs once format is
  // clear
  return success();
}

LogicalResult HeraclesSDKEmitter::printOperation(arith::ConstantOp op) {
  // TODO: How to deal with constants/immediates that might appear in the
  // code?
  emitWarning(
      op.getLoc(),
      "Heracles BGV Emitter currently ignores free-standing constants.");
  return success();
}

LogicalResult HeraclesSDKEmitter::printOperation(lwe::RLWEEncodeOp op) {
  // TODO: How to deal with plaintexts in code? Move outside to client helpers?
  emitWarning(op.getLoc(),
              "Heracles BGV Emitter currently ignores plaintext encoding ops.");
  return success();
}

LogicalResult HeraclesSDKEmitter::printOperation(lwe::RLWEDecodeOp op) {
  // TODO: How to deal with plaintexts in code? Move outside to client helpers?
  emitWarning(op.getLoc(),
              "Heracles BGV Emitter currently ignores plaintext decoding ops.");
  return success();
}

LogicalResult HeraclesSDKEmitter::printOperation(lwe::RLWEEncryptOp op) {
  // TODO: How to deal with encrypts in code? Move outside to client helpers?
  emitWarning(op.getLoc(),
              "Heracles BGV Emitter currently ignores encrypt ops.");
  return success();
}

LogicalResult HeraclesSDKEmitter::printOperation(lwe::RLWEDecryptOp op) {
  // TODO: How to deal with decrypts in code? Move outside to client helpers?
  emitWarning(op.getLoc(),
              "Heracles BGV Emitter currently ignores decrypt ops.");
  return success();
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::AddOp op) {
  return printHeraclesOp("add", "BGV", op.getResult(),
                         {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::AddOp op) {
  return printHeraclesOp("add", "CKKS", op.getResult(),
                         {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::AddPlainOp op) {
  return printHeraclesOp("add_plain", "BGV", op.getResult(),
                         {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::AddPlainOp op) {
  return printHeraclesOp("add_plain", "CKKS", op.getResult(),
                         {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::SubOp op) {
  // TODO: Is there no `sub` instruction?
  // Do we `mul_plain` one operand with ptxt(-1)?
  emitWarning(op.getLoc(),
              "Emitting potentially unsupported `sub` instruction");
  return printHeraclesOp("sub", "BGV", op.getResult(),
                         {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::SubOp op) {
  // TODO: Is there no `sub` instruction?
  // Do we `mul_plain` one operand with ptxt(-1)?
  emitWarning(op.getLoc(),
              "Emitting potentially unsupported `sub` instruction");
  return printHeraclesOp("sub", "CKKS", op.getResult(),
                         {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::SubPlainOp op) {
  // TODO: Is there no `sub_plain` instruction?
  // Do we `mul_plain` the ctxt operand with ptxt(-1) or can we negate the ptxt?
  emitWarning(op.getLoc(),
              "Emitting potentially unsupported `sub` instruction");
  return printHeraclesOp("sub_plain", "BGV", op.getResult(),
                         {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::SubPlainOp op) {
  // TODO: Is there no `sub_plain` instruction?
  // Do we `mul_plain` the ctxt operand with ptxt(-1) or can we negate the ptxt?
  emitWarning(op.getLoc(),
              "Emitting potentially unsupported `sub` instruction");
  return printHeraclesOp("sub_plain", "CKKS", op.getResult(),
                         {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::MulOp op) {
  if (op.getLhs() == op.getRhs()) {
    return printHeraclesOp("square", "BGV", op.getResult(), {op.getLhs()});
  }
  return printHeraclesOp("mul", "BGV", op.getResult(),
                         {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::MulOp op) {
  if (op.getLhs() == op.getRhs()) {
    return printHeraclesOp("square", "CKKS", op.getResult(), {op.getLhs()});
  }
  return printHeraclesOp("mul", "CKKS", op.getResult(),
                         {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::MulPlainOp op) {
  return printHeraclesOp("mul_plain", "BGV", op.getResult(),
                         {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::MulPlainOp op) {
  return printHeraclesOp("mul_plain", "CKKS", op.getResult(),
                         {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::NegateOp op) {
  // TODO: Looks like there is no `negate` instruction
  // We should probably emit a `mul_plain` with ptxt(-1) instead!
  emitWarning(op.getLoc(),
              "Emitting probably unsupported `negate` instruction");
  return printHeraclesOp("negate", "BGV", op.getResult(), {op.getInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::NegateOp op) {
  // TODO: Looks like there is no `negate` instruction
  // We should probably emit a `mul_plain` with ptxt(-1) instead!
  emitWarning(op.getLoc(),
              "Emitting probably unsupported `negate` instruction");
  return printHeraclesOp("negate", "CKKS", op.getResult(), {op.getInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::RelinearizeOp op) {
  if (!op.getFromBasis().equals({0, 1, 2}) || !op.getToBasis().equals({0, 1})) {
    emitWarning(op.getLoc(), "Heracles only supports 3-to-2 relinearization");
  }
  return printHeraclesOp("relin", "BGV", op.getResult(), {op.getInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::RelinearizeOp op) {
  if (!op.getFromBasis().equals({0, 1, 2}) || !op.getToBasis().equals({0, 1})) {
    emitWarning(op.getLoc(), "Heracles only supports 3-to-2 relinearization");
  }
  return printHeraclesOp("relin", "CKKS", op.getResult(), {op.getInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::RotateOp op) {
  return printHeraclesOp("rotate", "BGV", op.getResult(), {op.getInput()},
                         {op.getOffset().getInt()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::RotateOp op) {
  return printHeraclesOp("rotate", "CKKS", op.getResult(), {op.getInput()},
                         {op.getOffset().getInt()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::ModulusSwitchOp op) {
  // TODO: What does a modswitch need to look like?
  op->emitWarning("Ignoring ModSwitch Op in Heracles Emitter!!");
  return success();
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::RescaleOp op) {
  if (auto from = llvm::dyn_cast<rns::RNSType>(op.getInput()
                                                   .getType()
                                                   .getCiphertextSpace()
                                                   .getRing()
                                                   .getCoefficientType())) {
    if (auto to =
            llvm::dyn_cast<rns::RNSType>(op.getToRing().getCoefficientType())) {
      if (!from.getBasisTypes().drop_back().equals(to.getBasisTypes())) {
        emitWarning(
            op.getLoc(),
            "Unsupported rescale op with multiple steps in from/to basis "
            "encountered in Heracles Emitter.");
      }
      return printHeraclesOp("rescale", "CKKS", op.getResult(),
                             {op.getInput()});
    }
  }
  op->emitWarning("non-RNS rescale op encountered in Heracles Emitter!");
  return success();
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::ExtractOp op) {
  op->emitError("Heracles does not support extracting individual slots");
  return failure();
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::ExtractOp op) {
  op->emitError("Heracles does not support extracting individual slots");
  return failure();
}

FailureOr<HeraclesSDKEmitter::ValueNameInfo> HeraclesSDKEmitter::getNameInfo(
    Value value) {
  std::string name = variableNames->getNameForValue(value);
  bool is_ptxt = false;
  size_t poly_mod_degree = 0;
  size_t cur_rns_limbs = 1;
  size_t total_rns_terms = 0;
  size_t dimension = 0;

  polynomial::RingAttr ring;
  if (auto ptxt = dyn_cast<lwe::NewLWEPlaintextType>(value.getType())) {
    ring = ptxt.getPlaintextSpace().getRing();
    dimension = 1;
    is_ptxt = true;
  } else if (auto ctxt = dyn_cast<lwe::NewLWECiphertextType>(value.getType())) {
    ring = ctxt.getCiphertextSpace().getRing();
    dimension = ctxt.getCiphertextSpace().getSize();
    if (auto chain = ctxt.getModulusChain()) {
      total_rns_terms = chain.getElements().size();
    }

  } else {
    value.getDefiningOp()->emitError(
        "Unsupported result type for Heracles BGV Emitter");
    return failure();
  }
  poly_mod_degree = ring.getPolynomialModulus().getPolynomial().getDegree();
  if (auto rns = llvm::dyn_cast<rns::RNSType>(ring.getCoefficientType()))
    cur_rns_limbs = rns.getBasisTypes().size();

  return HeraclesSDKEmitter::ValueNameInfo({name, is_ptxt, poly_mod_degree,
                                            cur_rns_limbs, total_rns_terms,
                                            dimension});
}

std::string HeraclesSDKEmitter::prettyName(
    const HeraclesSDKEmitter::ValueNameInfo &info) {
  if (info.is_ptxt)
    return info.varname + "-" + std::to_string(info.dimension) + "-" +
           std::to_string(info.poly_mod_degree * info.cur_rns_limbs);
  return info.varname + "-" + std::to_string(info.dimension) + "-" +
         std::to_string(info.cur_rns_limbs);
};

LogicalResult HeraclesSDKEmitter::printHeraclesOp(
    std::string_view name, std::string_view scheme, Value result,
    ValueRange operands, std::vector<int64_t> immediates) {
  // TODO: What exactly are the semantics of the CSV format?
  // Do we need to check if there are any duplicate
  // occurrences in operands+result and, if there are, emit a copy operation
  // and replace them with the copy?

  auto result_info = getNameInfo(result);
  if (failed(result_info)) return failure();

  os << name << ", " << scheme << ", " << result_info->poly_mod_degree << ", "
     << result_info->total_rns_terms + 1 << ", " << prettyName(*result_info)
     << ", ";
  os << commaSeparatedValues(operands, [&](Value value) {
    auto info = getNameInfo(value);
    if (failed(info)) return variableNames->getNameForValue(value);
    return prettyName(*info);
  });
  for (auto i : immediates) {
    os << ", " << i;
  }
  os << "\n";
  return success();
}

HeraclesSDKEmitter::HeraclesSDKEmitter(raw_ostream &os,
                                       SelectVariableNames *variableNames,
                                       bool emitInputOnly)
    : os(os), emitInputOnly(emitInputOnly), variableNames(variableNames) {}

}  // namespace heracles
}  // namespace heir
}  // namespace mlir

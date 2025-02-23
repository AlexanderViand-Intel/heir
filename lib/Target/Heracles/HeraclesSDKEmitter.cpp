#include "lib/Target/Heracles/HeraclesSDKEmitter.h"

#include <stdexcept>

#include "heracles/fhe_trace/io.h"  // from @heracles_data_formats
#include "lib/Analysis/SelectVariableNames/SelectVariableNames.h"
#include "lib/Dialect/BGV/IR/BGVDialect.h"
#include "lib/Dialect/BGV/IR/BGVOps.h"
#include "lib/Dialect/CKKS/IR/CKKSDialect.h"
#include "lib/Dialect/CKKS/IR/CKKSOps.h"
#include "lib/Dialect/LWE/IR/LWEDialect.h"
#include "lib/Dialect/LWE/IR/LWEOps.h"
#include "lib/Dialect/LWE/IR/LWETypes.h"
#include "lib/Dialect/ModArith/IR/ModArithDialect.h"
#include "lib/Dialect/ModuleAttributes.h"
#include "lib/Dialect/Openfhe/IR/OpenfheDialect.h"
#include "lib/Dialect/Polynomial/IR/PolynomialDialect.h"
#include "lib/Dialect/RNS/IR/RNSDialect.h"
#include "lib/Dialect/RNS/IR/RNSTypes.h"
#include "lib/Utils/TargetUtils.h"
#include "llvm/include/llvm/ADT/TypeSwitch.h"            // from @llvm-project
#include "llvm/include/llvm/Support/Debug.h"             // from @llvm-project
#include "llvm/include/llvm/Support/FormatVariadic.h"    // from @llvm-project
#include "llvm/include/llvm/Support/ManagedStatic.h"     // from @llvm-project
#include "mlir/include/mlir/Dialect/Arith/IR/Arith.h"    // from @llvm-project
#include "mlir/include/mlir/Dialect/Func/IR/FuncOps.h"   // from @llvm-project
#include "mlir/include/mlir/Dialect/Tensor/IR/Tensor.h"  // from @llvm-project
#include "mlir/include/mlir/Support/LLVM.h"              // from @llvm-project
#include "mlir/include/mlir/Tools/mlir-translate/Translation.h"  // from @llvm-project

#define DEBUG_TYPE "HeraclesSDKEmitter"

namespace mlir {
namespace heir {
namespace heracles {

struct TranslateOptions {
  llvm::cl::opt<mlir::heir::heracles::HeraclesOutputFormat> outputFormat{
      "heracles-output-format",
      llvm::cl::desc("The data format to use for emitting data and "
                     "instructions to the Heracles SDK"),
      llvm::cl::init(mlir::heir::heracles::HeraclesOutputFormat::LEGACY_CSV),
      llvm::cl::values(
          clEnumValN(mlir::heir::heracles::HeraclesOutputFormat::LEGACY_CSV,
                     "legacy-csv",
                     "Emit data and instructions in the legacy CSV format."),
          clEnumValN(mlir::heir::heracles::HeraclesOutputFormat::PROTOBUF,
                     "protobuf",
                     "Emit data and instructions using heracles-data-format "
                     "protobuf definitions."))};
};
static llvm::ManagedStatic<TranslateOptions> options;

void registerHeraclesTranslateOptions() {
  // Forces initialization of options.
  *options;
}

void registerToHeraclesSDKTranslation() {
  TranslateFromMLIRRegistration reg(
      "emit-heracles-sdk",
      "translate bgv or ckks dialect to textual Heracles SDK representation",
      [](Operation *op, llvm::raw_ostream &output) {
        return translateToHeraclesInstructions(op, output,
                                               options->outputFormat);
      },
      [](DialectRegistry &registry) {
        registry.insert<arith::ArithDialect, func::FuncDialect,
                        tensor::TensorDialect, bgv::BGVDialect,
                        polynomial::PolynomialDialect, ckks::CKKSDialect,
                        openfhe::OpenfheDialect, lwe::LWEDialect,
                        mod_arith::ModArithDialect, rns::RNSDialect>();
        rns::registerExternalRNSTypeInterfaces(registry);
      });
}

LogicalResult translateToHeraclesInstructions(
    Operation *op, llvm::raw_ostream &os, HeraclesOutputFormat outputFormat) {
  SelectVariableNames variableNames(op, false);
  HeraclesSDKEmitter emitter(os, &variableNames, outputFormat);
  auto result = emitter.translate(*op);
  if (outputFormat == HeraclesOutputFormat::PROTOBUF && result.succeeded()) {
    return emitter.dump_trace();
  }
  return result;
}

LogicalResult HeraclesSDKEmitter::dump_trace() {
  LLVM_DEBUG(llvm::dbgs() << trace.DebugString());
  std::ostringstream oss;
  trace.SerializeToOstream(&oss);
  // FIXME: This seems inefficient, but should be ok for testing
  os.getOStream() << oss.str();

  return success();
}

// FIXME: Throw an error if add/sub/etc dimensions do not match
LogicalResult HeraclesSDKEmitter::translate(::mlir::Operation &op) {
  bool csv = options->outputFormat == HeraclesOutputFormat::LEGACY_CSV;
  auto translate = [&](auto op) {
    return csv ? printOperation(op) : emitOperation(op);
  };

  LogicalResult status =
      llvm::TypeSwitch<Operation &, LogicalResult>(op)
          .Case<
              // Builtin ops
              ModuleOp,
              // Func ops
              func::FuncOp,
              // LWE Ops
              lwe::RAddOp, lwe::RSubOp, lwe::RMulOp,
              lwe::ReinterpretUnderlyingTypeOp,
              // BGV Ops
              bgv::AddOp, bgv::AddPlainOp, bgv::SubOp, bgv::SubPlainOp,
              bgv::MulOp, bgv::MulPlainOp, bgv::NegateOp, bgv::RelinearizeOp,
              bgv::RotateOp, bgv::ModulusSwitchOp, bgv::ExtractOp,
              // CKKS Ops
              ckks::AddOp, ckks::AddPlainOp, ckks::SubOp, ckks::SubPlainOp,
              ckks::MulOp, ckks::MulPlainOp, ckks::NegateOp,
              ckks::RelinearizeOp, ckks::RotateOp, ckks::RescaleOp,
              ckks::ExtractOp>([&](auto op) { return translate(op); })
          .Case<
              // FIXME: make these hard errors and move encode to helper
              // function! No-Op operations this emitter can skip for now
              lwe::RLWEEncodeOp, lwe::RLWEDecodeOp, lwe::RLWEEncryptOp,
              lwe::RLWEDecryptOp, func::ReturnOp>([&](auto op) {
            emitWarning(op.getLoc(), "Skipping operation.");
            return success();
          })
          .Default([&](Operation &) {
            return emitError(op.getLoc(), "unable to find emitter for op");
          });

  if (failed(status)) {
    emitError(op.getLoc(),
              llvm::formatv("Failed to translate op {0}", op.getName()));
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
                "Heracles SDK Emitter only supports code wrapped in functions. "
                "Operation will not be translated.");
      continue;
    }  // FIXME: once the entry_function heuristics are merged, add an
    // entry_function option that falls back to the heuristic and only warn if
    // that fails We now have many different functions because of enc/dec!
    // if (++funcs > 1)
    // emitWarning(op.getLoc(),
    //             "Heracles SDK Emitter is designed for single functions. "
    //             "Inputs, outputs and bodies of different functions "
    //             "will be merged.");
    if (failed(translate(op))) {
      return failure();
    }
  }
  return success();
}

LogicalResult HeraclesSDKEmitter::emitOperation(ModuleOp moduleOp) {
  if (moduleOp->getAttr(kCKKSSchemeAttrName))
    trace.set_scheme(sdk::common::Scheme::SCHEME_CKKS);
  else if (moduleOp->getAttr(kBGVSchemeAttrName))
    trace.set_scheme(sdk::common::Scheme::SCHEME_BGV);
  else {
    emitError(moduleOp.getLoc(),
              "Missing or unknown scheme attribute on module");
    return failure();
  }
  // FIXME: find the key_rns_num and ciphertext degree by looking at the
  // function arguments. For now we just override them whenever we find bigger
  // ones.
  trace.set_key_rns_num(1);
  trace.set_n(1);

  // Emit function body/bodies
  int funcs = 0;
  for (Operation &op : moduleOp) {
    if (!llvm::isa<func::FuncOp>(op)) {
      emitError(op.getLoc(),
                "Heracles SDK Emitter only supports code wrapped in functions. "
                "Operation will not be translated.");
      continue;
    }
    // FIXME: once the entry_function heuristics are merged, add an
    // entry_function option that falls back to the heuristic and only warn if
    // that fails We now have many different functions because of enc/dec!
    // if (++funcs > 1)
    // emitWarning(op.getLoc(),
    //               "Heracles SDK Emitter is designed for single functions. "
    //               "Inputs, outputs and bodies of different functions "
    //               "will be merged.");
    if (failed(translate(op))) {
      return failure();
    }
  }
  return success();
}

LogicalResult HeraclesSDKEmitter::printOperation(func::FuncOp funcOp) {
  // If function name starts with `__`, skip it
  if (funcOp.getName().str().rfind("__", 0)) {
    LLVM_DEBUG(emitWarning(funcOp.getLoc(), "Skipping function '__'."));
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

LogicalResult HeraclesSDKEmitter::emitOperation(func::FuncOp funcOp) {
  // If function name starts with `__`, skip it
  if (funcOp.getName().str().rfind("__", 0)) {
    LLVM_DEBUG(emitWarning(funcOp.getLoc(), "Skipping function '__'."));
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

LogicalResult HeraclesSDKEmitter::printOperation(
    lwe::ReinterpretUnderlyingTypeOp op) {
  emitWarning(op.getLoc(),
              "Heracles SDK Emitter currently emits redundant `copy` for "
              "reinterpret ops.");

  auto module = op->getParentOfType<ModuleOp>();
  std::string scheme = "";
  if (module->getAttr(kCKKSSchemeAttrName))
    scheme = "CKKS";
  else if (module->getAttr(kBGVSchemeAttrName))
    scheme = "BGV";
  else {
    emitError(op.getLoc(), "Missing or unknown scheme attribute on module");
    return failure();
  }
  return printOpHelper("copy", scheme, op.getOutput(), {op.getInput()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(
    lwe::ReinterpretUnderlyingTypeOp op) {
  assert(false);
  throw std::logic_error("Not yet implemented.");  // FIXME: implement
}

LogicalResult HeraclesSDKEmitter::printOperation(lwe::RAddOp op) {
  auto module = op->getParentOfType<ModuleOp>();
  std::string scheme = "";
  if (module->getAttr(kCKKSSchemeAttrName))
    scheme = "CKKS";
  else if (module->getAttr(kBGVSchemeAttrName))
    scheme = "BGV";
  else {
    emitError(op.getLoc(), "Missing or unknown scheme attribute on module");
    return failure();
  }

  return printOpHelper("add", scheme, op.getResult(),
                       {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(lwe::RAddOp op) {
  auto module = op->getParentOfType<ModuleOp>();
  sdk::common::Scheme scheme;
  if (module->getAttr(kCKKSSchemeAttrName))
    scheme = sdk::common::Scheme::SCHEME_CKKS;
  else if (module->getAttr(kBGVSchemeAttrName))
    scheme = sdk::common::Scheme::SCHEME_BGV;
  else {
    emitError(op.getLoc(), "Missing or unknown scheme attribute on module");
    return failure();
  }

  return emitOpHelper("add", scheme, op.getResult(),
                      {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::printOperation(lwe::RSubOp op) {
  auto module = op->getParentOfType<ModuleOp>();
  std::string scheme = "";
  if (module->getAttr(kCKKSSchemeAttrName))
    scheme = "CKKS";
  else if (module->getAttr(kBGVSchemeAttrName))
    scheme = "BGV";
  else {
    emitError(op.getLoc(), "Missing or unknown scheme attribute on module");
    return failure();
  }
  return printOpHelper("sub", scheme, op.getResult(),
                       {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(lwe::RSubOp op) {
  assert(false);
  throw std::logic_error("Not yet implemented.");  // FIXME: implement
}

LogicalResult HeraclesSDKEmitter::printOperation(lwe::RMulOp op) {
  auto module = op->getParentOfType<ModuleOp>();
  std::string scheme = "";
  if (module->getAttr(kCKKSSchemeAttrName))
    scheme = "CKKS";
  else if (module->getAttr(kBGVSchemeAttrName))
    scheme = "BGV";
  else {
    emitError(op.getLoc(), "Missing or unknown scheme attribute on module");
    return failure();
  }

  if (op.getLhs() == op.getRhs()) {
    return printOpHelper("square", scheme, op.getResult(), {op.getLhs()});
  }

  return printOpHelper("mul", scheme, op.getResult(),
                       {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(lwe::RMulOp op) {
  assert(false);
  throw std::logic_error("Not yet implemented.");  // FIXME: implement
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::AddOp op) {
  return printOpHelper("add", "BGV", op.getResult(),
                       {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(bgv::AddOp op) {
  return emitOpHelper("add", sdk::common::Scheme::SCHEME_BGV, op.getResult(),
                      {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::AddOp op) {
  return printOpHelper("add", "CKKS", op.getResult(),
                       {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(ckks::AddOp op) {
  return emitOpHelper("add", sdk::common::Scheme::SCHEME_CKKS, op.getResult(),
                      {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::AddPlainOp op) {
  return printOpHelper("add_plain", "BGV", op.getResult(),
                       {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(bgv::AddPlainOp op) {
  return emitOpHelper("add_plain", sdk::common::Scheme::SCHEME_BGV,
                      op.getResult(),
                      {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::AddPlainOp op) {
  return printOpHelper("add_plain", "CKKS", op.getResult(),
                       {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(ckks::AddPlainOp op) {
  return emitOpHelper("add_plain", sdk::common::Scheme::SCHEME_CKKS,
                      op.getResult(),
                      {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::SubOp op) {
  return printOpHelper("sub", "BGV", op.getResult(),
                       {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(bgv::SubOp op) {
  return emitOpHelper("sub", sdk::common::Scheme::SCHEME_BGV, op.getResult(),
                      {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::SubOp op) {
  return printOpHelper("sub", "CKKS", op.getResult(),
                       {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(ckks::SubOp op) {
  return emitOpHelper("sub", sdk::common::Scheme::SCHEME_CKKS, op.getResult(),
                      {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::SubPlainOp op) {
  return printOpHelper("sub_plain", "BGV", op.getResult(),
                       {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(bgv::SubPlainOp op) {
  return emitOpHelper("sub_plain", sdk::common::Scheme::SCHEME_BGV,
                      op.getResult(),
                      {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::SubPlainOp op) {
  return printOpHelper("sub_plain", "CKKS", op.getResult(),
                       {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(ckks::SubPlainOp op) {
  return emitOpHelper("sub_plain", sdk::common::Scheme::SCHEME_CKKS,
                      op.getResult(),
                      {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::MulOp op) {
  if (op.getLhs() == op.getRhs()) {
    return printOpHelper("square", "BGV", op.getResult(), {op.getLhs()});
  }
  return printOpHelper("mul", "BGV", op.getResult(),
                       {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(bgv::MulOp op) {
  if (op.getLhs() == op.getRhs()) {
    return emitOpHelper("square", sdk::common::Scheme::SCHEME_BGV,
                        op.getResult(), {op.getLhs()});
  }
  return emitOpHelper("mul", sdk::common::Scheme::SCHEME_BGV, op.getResult(),
                      {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::MulOp op) {
  if (op.getLhs() == op.getRhs()) {
    return printOpHelper("square", "CKKS", op.getResult(), {op.getLhs()});
  }
  return printOpHelper("mul", "CKKS", op.getResult(),
                       {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(ckks::MulOp op) {
  if (op.getLhs() == op.getRhs()) {
    return emitOpHelper("square", sdk::common::Scheme::SCHEME_CKKS,
                        op.getResult(), {op.getLhs()});
  }
  return emitOpHelper("mul", sdk::common::Scheme::SCHEME_CKKS, op.getResult(),
                      {op.getLhs(), op.getRhs()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::MulPlainOp op) {
  return printOpHelper("mul_plain", "BGV", op.getResult(),
                       {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(bgv::MulPlainOp op) {
  return emitOpHelper("mul_plain", sdk::common::Scheme::SCHEME_BGV,
                      op.getResult(),
                      {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::MulPlainOp op) {
  return printOpHelper("mul_plain", "CKKS", op.getResult(),
                       {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(ckks::MulPlainOp op) {
  return emitOpHelper("mul_plain", sdk::common::Scheme::SCHEME_CKKS,
                      op.getResult(),
                      {op.getCiphertextInput(), op.getPlaintextInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::NegateOp op) {
  // FIXME: There is no `negate` instruction, emit a `mul_plain` with ptxt(-1)
  emitWarning(op.getLoc(), "Emitting unsupported `negate` instruction");
  return printOpHelper("negate", "BGV", op.getResult(), {op.getInput()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(bgv::NegateOp op) {
  // FIXME: There is no `negate` instruction, emit a `mul_plain` with ptxt(-1)
  emitWarning(op.getLoc(), "Emitting unsupported `negate` instruction");
  return emitOpHelper("negate", sdk::common::Scheme::SCHEME_BGV, op.getResult(),
                      {op.getInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::NegateOp op) {
  // FIXME: There is no `negate` instruction, emit a `mul_plain` with ptxt(-1)
  emitWarning(op.getLoc(), "Emitting unsupported `negate` instruction");
  return printOpHelper("negate", "CKKS", op.getResult(), {op.getInput()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(ckks::NegateOp op) {
  // FIXME: There is no `negate` instruction, emit a `mul_plain` with ptxt(-1)
  emitWarning(op.getLoc(), "Emitting unsupported `negate` instruction");
  return emitOpHelper("negate", sdk::common::Scheme::SCHEME_CKKS,
                      op.getResult(), {op.getInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::RelinearizeOp op) {
  if (!op.getFromBasis().equals({0, 1, 2}) || !op.getToBasis().equals({0, 1})) {
    emitError(op.getLoc(), "Heracles only supports 3-to-2 relinearization");
  }
  return printOpHelper("relin", "BGV", op.getResult(), {op.getInput()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(bgv::RelinearizeOp op) {
  if (!op.getFromBasis().equals({0, 1, 2}) || !op.getToBasis().equals({0, 1})) {
    emitError(op.getLoc(), "Heracles only supports 3-to-2 relinearization");
  }
  return emitOpHelper("relin", sdk::common::Scheme::SCHEME_BGV, op.getResult(),
                      {op.getInput()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::RelinearizeOp op) {
  if (!op.getFromBasis().equals({0, 1, 2}) || !op.getToBasis().equals({0, 1})) {
    emitError(op.getLoc(), "Heracles only supports 3-to-2 relinearization");
  }
  return printOpHelper("relin", "CKKS", op.getResult(), {op.getInput()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(ckks::RelinearizeOp op) {
  if (!op.getFromBasis().equals({0, 1, 2}) || !op.getToBasis().equals({0, 1})) {
    emitError(op.getLoc(), "Heracles only supports 3-to-2 relinearization");
  }
  return emitOpHelper("relin", sdk::common::Scheme::SCHEME_CKKS, op.getResult(),
                      {op.getInput()});
}

// TODO:
LogicalResult HeraclesSDKEmitter::printOperation(bgv::RotateOp op) {
  return printOpHelper("rotate", "BGV", op.getResult(), {op.getInput()},
                       {op.getOffset().getInt()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(bgv::RotateOp op) {
  return emitOpHelper("rotate", sdk::common::Scheme::SCHEME_BGV, op.getResult(),
                      {op.getInput()}, {op.getOffset().getInt()});
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::RotateOp op) {
  return printOpHelper("rotate", "CKKS", op.getResult(), {op.getInput()},
                       {op.getOffset().getInt()});
}

LogicalResult HeraclesSDKEmitter::emitOperation(ckks::RotateOp op) {
  return emitOpHelper("rotate", sdk::common::Scheme::SCHEME_CKKS,
                      op.getResult(), {op.getInput()},
                      {op.getOffset().getInt()});
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::ModulusSwitchOp op) {
  if (auto from = llvm::dyn_cast<rns::RNSType>(op.getInput()
                                                   .getType()
                                                   .getCiphertextSpace()
                                                   .getRing()
                                                   .getCoefficientType())) {
    if (auto to =
            llvm::dyn_cast<rns::RNSType>(op.getToRing().getCoefficientType())) {
      if (!from.getBasisTypes().drop_back().equals(to.getBasisTypes())) {
        emitError(
            op.getLoc(),
            "Unsupported mod_switch op with multiple steps in from/to basis "
            "encountered in Heracles Emitter.");
      }
      return printOpHelper("mod_switch", "BGV", op.getResult(),
                           {op.getInput()});
    }
  }
  op->emitWarning("non-RNS mod_switch op encountered in Heracles Emitter!");
  return success();
}

LogicalResult HeraclesSDKEmitter::emitOperation(bgv::ModulusSwitchOp op) {
  if (auto from = llvm::dyn_cast<rns::RNSType>(op.getInput()
                                                   .getType()
                                                   .getCiphertextSpace()
                                                   .getRing()
                                                   .getCoefficientType())) {
    if (auto to =
            llvm::dyn_cast<rns::RNSType>(op.getToRing().getCoefficientType())) {
      if (!from.getBasisTypes().drop_back().equals(to.getBasisTypes())) {
        emitError(
            op.getLoc(),
            "Unsupported mod_switch op with multiple steps in from/to basis "
            "encountered in Heracles Emitter.");
      }
      return emitOpHelper("mod_switch", sdk::common::Scheme::SCHEME_BGV,
                          op.getResult(), {op.getInput()});
    }
  }
  op->emitWarning("non-RNS mod_switch op encountered in Heracles Emitter!");
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
        emitError(op.getLoc(),
                  "Unsupported rescale op with multiple steps in from/to basis "
                  "encountered in Heracles Emitter.");
      }
      return printOpHelper("rescale", "CKKS", op.getResult(), {op.getInput()});
    }
  }
  op->emitWarning("non-RNS rescale op encountered in Heracles Emitter!");
  return success();
}

LogicalResult HeraclesSDKEmitter::emitOperation(ckks::RescaleOp op) {
  if (auto from = llvm::dyn_cast<rns::RNSType>(op.getInput()
                                                   .getType()
                                                   .getCiphertextSpace()
                                                   .getRing()
                                                   .getCoefficientType())) {
    if (auto to =
            llvm::dyn_cast<rns::RNSType>(op.getToRing().getCoefficientType())) {
      if (!from.getBasisTypes().drop_back().equals(to.getBasisTypes())) {
        emitError(op.getLoc(),
                  "Unsupported rescale op with multiple steps in from/to basis "
                  "encountered in Heracles Emitter.");
      }
      return emitOpHelper("rescale", sdk::common::Scheme::SCHEME_CKKS,
                          op.getResult(), {op.getInput()});
    }
  }
  op->emitWarning("non-RNS rescale op encountered in Heracles Emitter!");
  return success();
}

LogicalResult HeraclesSDKEmitter::printOperation(bgv::ExtractOp op) {
  op->emitError("Heracles does not support extracting individual slots");
  return failure();
}

LogicalResult HeraclesSDKEmitter::emitOperation(bgv::ExtractOp op) {
  op->emitError("Heracles does not support extracting individual slots");
  return failure();
}

LogicalResult HeraclesSDKEmitter::printOperation(ckks::ExtractOp op) {
  op->emitError("Heracles does not support extracting individual slots");
  return failure();
}

LogicalResult HeraclesSDKEmitter::emitOperation(ckks::ExtractOp op) {
  op->emitError("Heracles does not support extracting individual slots");
  return failure();
}

LogicalResult HeraclesSDKEmitter::emitOpHelper(
    std::string_view name, sdk::common::Scheme scheme, Value result,
    ValueRange operands, std::vector<int64_t> immediates) {
  auto instr = trace.add_instructions();
  instr->set_op(name);
  // operands and results
  auto instr_args = instr->mutable_args();

  // operands
  for (auto operand : operands) {
    auto name = variableNames->getNameForValue(operand);
    auto info = getNameInfo(name, operand);
    if (failed(info)) return failure();

    auto src = instr_args->add_srcs();
    src->set_symbol_name(info->varname);
    src->set_order(info->dimension);
    src->set_num_rns(info->cur_rns_limbs);

    // FIXME: little hack for now:
    if (trace.n() < info->poly_mod_degree) {
      trace.set_n(info->poly_mod_degree);
    }
    if (trace.key_rns_num() < info->total_rns_terms) {
      trace.set_key_rns_num(info->total_rns_terms);
    }
  }

  // results
  for (auto result : operands) {
    std::string name = variableNames->getNameForValue(result);
    auto info = getNameInfo(name, result);
    if (failed(info)) return failure();

    auto dest = instr_args->add_dests();
    dest->set_symbol_name(info->varname);
    dest->set_order(info->dimension);
    dest->set_num_rns(info->cur_rns_limbs);
  }

  return success();
}

LogicalResult HeraclesSDKEmitter::printOpHelper(
    std::string_view name, std::string_view scheme, Value result,
    ValueRange operands, std::vector<int64_t> immediates) {
  // TODO: What exactly are the semantics of the CSV format?
  // Do we need to check if there are any duplicate
  // occurrences in operands+result and, if there are, emit a copy operation
  // and replace them with the copy?
  auto result_name = variableNames->getNameForValue(result);
  auto result_info = getNameInfo(result_name, result);
  if (failed(result_info)) return failure();

  os << name << "," << scheme << "," << result_info->poly_mod_degree << ","
     << result_info->total_rns_terms + 1 << "," << prettyName(*result_info)
     << ",";
  os << commaSeparatedValues(
      operands,
      [&](Value value) {
        auto n = variableNames->getNameForValue(value);
        auto info = getNameInfo(n, value);
        return prettyName(*info);
      },
      false);
  for (auto i : immediates) {
    os << ", " << i;
  }
  os << "\n";
  return success();
}

HeraclesSDKEmitter::HeraclesSDKEmitter(raw_ostream &os,
                                       SelectVariableNames *variableNames,
                                       HeraclesOutputFormat outputFormat)
    : os(os), variableNames(variableNames) {}

}  // namespace heracles
}  // namespace heir
}  // namespace mlir

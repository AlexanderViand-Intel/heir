#ifndef LIB_TARGET_HERACLES_HERACLESSDKEMITTER_H_
#define LIB_TARGET_HERACLES_HERACLESSDKEMITTER_H_

#include <string_view>

#include "heracles/proto/fhe_trace.pb.h"  // from @heracles-data-formats
#include "lib/Analysis/SelectVariableNames/SelectVariableNames.h"
#include "lib/Dialect/BGV/IR/BGVOps.h"
#include "lib/Dialect/CKKS/IR/CKKSOps.h"
#include "lib/Dialect/LWE/IR/LWEOps.h"
#include "lib/Target/Heracles/HeraclesUtils.h"
#include "llvm/include/llvm/Support/raw_ostream.h"      // from @llvm-project
#include "mlir/include/mlir/Dialect/Func/IR/FuncOps.h"  // from @llvm-project
#include "mlir/include/mlir/IR/BuiltinOps.h"            // from @llvm-project
#include "mlir/include/mlir/Support/IndentedOstream.h"  // from @llvm-project
#include "mlir/include/mlir/Support/LogicalResult.h"    // from @llvm-project
namespace mlir {
namespace heir {
namespace heracles {

namespace sdk = ::heracles;

void registerHeraclesTranslateOptions();
void registerToHeraclesSDKTranslation();

/// Translates the given operation to the Heracles SDK (scheme level) format
LogicalResult translateToHeraclesInstructions(
    Operation *op, llvm::raw_ostream &os, HeraclesOutputFormat outputFormat);

class HeraclesSDKEmitter {
 public:
  HeraclesSDKEmitter(raw_ostream &os, SelectVariableNames *variableNames,
                     HeraclesOutputFormat outputFormat);

  LogicalResult translate(::mlir::Operation &operation);

  /// When in PROTOBUF mode, dump the trace to the output stream
  LogicalResult dump_trace();

 private:
  /// Output stream to emit to when using output format LEGACY_CSV
  raw_indented_ostream os;

  /// Output protobuf trace to emit when using output format PROTOBUF
  sdk::fhe_trace::Trace trace;

  /// Pre-populated analysis selecting unique variable names for all the SSA
  /// values.
  SelectVariableNames *variableNames;

  // Functions for emitting individual ops to protobuf
  LogicalResult emitOperation(::mlir::ModuleOp op);
  LogicalResult emitOperation(::mlir::func::FuncOp op);
  LogicalResult emitOperation(lwe::ReinterpretUnderlyingTypeOp op);
  LogicalResult emitOperation(lwe::RAddOp op);
  LogicalResult emitOperation(lwe::RSubOp op);
  LogicalResult emitOperation(lwe::RMulOp op);
  LogicalResult emitOperation(bgv::AddOp op);
  LogicalResult emitOperation(bgv::AddPlainOp op);
  LogicalResult emitOperation(bgv::SubOp op);
  LogicalResult emitOperation(bgv::SubPlainOp op);
  LogicalResult emitOperation(bgv::MulOp op);
  LogicalResult emitOperation(bgv::MulPlainOp op);
  LogicalResult emitOperation(bgv::NegateOp op);
  LogicalResult emitOperation(bgv::RelinearizeOp op);
  LogicalResult emitOperation(bgv::RotateOp op);
  LogicalResult emitOperation(bgv::ModulusSwitchOp op);
  LogicalResult emitOperation(bgv::ExtractOp op);
  LogicalResult emitOperation(ckks::AddOp op);
  LogicalResult emitOperation(ckks::AddPlainOp op);
  LogicalResult emitOperation(ckks::SubOp op);
  LogicalResult emitOperation(ckks::SubPlainOp op);
  LogicalResult emitOperation(ckks::MulOp op);
  LogicalResult emitOperation(ckks::MulPlainOp op);
  LogicalResult emitOperation(ckks::NegateOp op);
  LogicalResult emitOperation(ckks::RelinearizeOp op);
  LogicalResult emitOperation(ckks::RotateOp op);
  LogicalResult emitOperation(ckks::RescaleOp op);
  LogicalResult emitOperation(ckks::ExtractOp op);

  // Helper for above
  LogicalResult emitOpHelper(std::string_view name, sdk::common::Scheme scheme,
                             Value result, ValueRange operands,
                             std::vector<int64_t> immediates = {});

  // Functions for printing individual ops to CSV
  LogicalResult printOperation(::mlir::ModuleOp op);
  LogicalResult printOperation(::mlir::func::FuncOp op);
  LogicalResult printOperation(lwe::ReinterpretUnderlyingTypeOp op);
  LogicalResult printOperation(lwe::RAddOp op);
  LogicalResult printOperation(lwe::RSubOp op);
  LogicalResult printOperation(lwe::RMulOp op);
  LogicalResult printOperation(bgv::AddOp op);
  LogicalResult printOperation(bgv::AddPlainOp op);
  LogicalResult printOperation(bgv::SubOp op);
  LogicalResult printOperation(bgv::SubPlainOp op);
  LogicalResult printOperation(bgv::MulOp op);
  LogicalResult printOperation(bgv::MulPlainOp op);
  LogicalResult printOperation(bgv::NegateOp op);
  LogicalResult printOperation(bgv::RelinearizeOp op);
  LogicalResult printOperation(bgv::RotateOp op);
  LogicalResult printOperation(bgv::ModulusSwitchOp op);
  LogicalResult printOperation(bgv::ExtractOp op);
  LogicalResult printOperation(ckks::AddOp op);
  LogicalResult printOperation(ckks::AddPlainOp op);
  LogicalResult printOperation(ckks::SubOp op);
  LogicalResult printOperation(ckks::SubPlainOp op);
  LogicalResult printOperation(ckks::MulOp op);
  LogicalResult printOperation(ckks::MulPlainOp op);
  LogicalResult printOperation(ckks::NegateOp op);
  LogicalResult printOperation(ckks::RelinearizeOp op);
  LogicalResult printOperation(ckks::RotateOp op);
  LogicalResult printOperation(ckks::RescaleOp op);
  LogicalResult printOperation(ckks::ExtractOp op);

  // Helper for above
  LogicalResult printOpHelper(std::string_view name, std::string_view scheme,
                              Value result, ValueRange operands,
                              std::vector<int64_t> immediates = {});
};

}  // namespace heracles
}  // namespace heir
}  // namespace mlir

#endif  // LIB_TARGET_HERACLES_HERACLESSDKEMITTER_H_

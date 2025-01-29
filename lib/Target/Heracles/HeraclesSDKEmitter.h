#ifndef LIB_TARGET_HERACLES_HERACLESSDKEMITTER_H_
#define LIB_TARGET_HERACLES_HERACLESSDKEMITTER_H_

#include <string_view>

#include "lib/Analysis/SelectVariableNames/SelectVariableNames.h"
#include "lib/Dialect/BGV/IR/BGVOps.h"
#include "lib/Dialect/CKKS/IR/CKKSOps.h"
#include "lib/Dialect/LWE/IR/LWEOps.h"
#include "lib/Dialect/ModArith/IR/ModArithOps.h"
#include "lib/Dialect/RNS/IR/RNSOps.h"
#include "llvm/include/llvm/Support/raw_ostream.h"      // from @llvm-project
#include "mlir/include/mlir/Dialect/Arith/IR/Arith.h"   // from @llvm-project
#include "mlir/include/mlir/Dialect/Func/IR/FuncOps.h"  // from @llvm-project
#include "mlir/include/mlir/IR/BuiltinOps.h"            // from @llvm-project
#include "mlir/include/mlir/Support/IndentedOstream.h"  // from @llvm-project
#include "mlir/include/mlir/Support/LogicalResult.h"    // from @llvm-project

namespace mlir {
namespace heir {
namespace heracles {

void registerToHeraclesSDKTranslation();
// FIXME: What's the format for defining inputs?
// void registerToHeraclesBGVInputsTranslation();

/// Translates the given operation to the Heracles SDK (scheme level) format
LogicalResult translateToHeraclesBGV(Operation *op, llvm::raw_ostream &os,
                                     bool emitInputOnly);

class HeraclesSDKEmitter {
 public:
  HeraclesSDKEmitter(raw_ostream &os, SelectVariableNames *variableNames,
                     bool emitInputOnly);

  LogicalResult translate(::mlir::Operation &operation);

 private:
  /// Output stream to emit to.
  raw_indented_ostream os;

  /// Whether to only output input/output file or instruction stream
  bool emitInputOnly;

  /// Pre-populated analysis selecting unique variable names for all the SSA
  /// values.
  SelectVariableNames *variableNames;

  // Functions for printing individual ops
  LogicalResult printOperation(::mlir::ModuleOp op);
  LogicalResult printOperation(::mlir::arith::ConstantOp op);
  LogicalResult printOperation(::mlir::func::FuncOp op);
  LogicalResult printOperation(::mlir::func::ReturnOp op);
  LogicalResult printOperation(lwe::RLWEEncodeOp op);
  LogicalResult printOperation(lwe::RLWEDecodeOp op);
  LogicalResult printOperation(lwe::RLWEEncryptOp op);
  LogicalResult printOperation(lwe::RLWEDecryptOp op);
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
  LogicalResult printHeraclesOp(std::string_view name, std::string_view scheme,
                                Value result, ValueRange operands,
                                std::vector<int64_t> immediates = {});

  /// info used to construct variable names for SSA values
  struct ValueNameInfo {
    /// Name as determined by SelectVariableNames (getNameForValue)
    std::string varname;
    /// Whether the current value is a plaintext or ciphertext
    bool is_ptxt;
    /// Polynomial modulus degree
    size_t poly_mod_degree;
    /// Current number of rns_limbs
    size_t cur_rns_limbs;
    /// Total number of rns terms in the modulus chain (only if not ptxt!)
    size_t total_rns_terms;
    /// Dimension of Ctxt (1 if Ptxt)
    size_t dimension;
  };

  FailureOr<HeraclesSDKEmitter::ValueNameInfo> getNameInfo(Value value);
  std::string prettyName(const HeraclesSDKEmitter::ValueNameInfo &info);
};

}  // namespace heracles
}  // namespace heir
}  // namespace mlir

#endif  // LIB_TARGET_HERACLES_HERACLESSDKEMITTER_H_

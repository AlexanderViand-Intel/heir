#ifndef LIB_TARGET_HERACLES_HERACLESUTILS_H_
#define LIB_TARGET_HERACLES_HERACLESUTILS_H_

#include <string>

#include "mlir/include/mlir/IR/Value.h"               // from @llvm-project
#include "mlir/include/mlir/Support/LogicalResult.h"  // from @llvm-project
namespace mlir {
namespace heir {
namespace heracles {

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

FailureOr<ValueNameInfo> getNameInfo(const std::string &name, Value value);
std::string prettyName(const ValueNameInfo &info);

enum class HeraclesOutputFormat {
  // data and instruction files in the legacy Heracles SDK CSV format
  LEGACY_CSV,
  // heracles-data-formats protobuf definition for data and instructions
  PROTOBUF
};

}  // namespace heracles
}  // namespace heir
}  // namespace mlir

#endif  // LIB_TARGET_HERACLES_HERACLESUTILS_H_

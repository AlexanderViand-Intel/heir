#ifndef LIB_DIALECT_RNS_IR_RNSTRAITS_H_
#define LIB_DIALECT_RNS_IR_RNSTRAITS_H_

#include "mlir/include/mlir/IR/OpDefinition.h"  // from @llvm-project

namespace mlir {
namespace heir {
namespace rns {

/// An operation that is `RNSizable` is an operation that can be applied
/// to each of the RNS limbs of its RNS operands independently.
///
/// This is basically 'Scalarizable' from MLIR, but with RNS limbs.
template <typename ConcreteType>
struct RNSizable : public OpTrait::TraitBase<ConcreteType, RNSizable> {
  static LogicalResult verifyTrait(Operation *op) {
    static_assert(ConcreteType::template hasTrait<OpTrait::Elementwise>(),
                  "`RNSizable` trait is only applicable to `Elementwise` ops.");
    return success();
  }
};

}  // namespace rns
}  // namespace heir
}  // namespace mlir

#endif  // LIB_DIALECT_RNS_IR_RNSTRAITS_H_

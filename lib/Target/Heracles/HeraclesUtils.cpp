#include "lib/Target/Heracles/HeraclesUtils.h"

#include "lib/Dialect/LWE/IR/LWETypes.h"
#include "lib/Dialect/ModArith/IR/ModArithTypes.h"
#include "lib/Dialect/Polynomial/IR/PolynomialTypes.h"
#include "lib/Dialect/RNS/IR/RNSTypes.h"

namespace mlir {
namespace heir {
namespace heracles {

FailureOr<ValueNameInfo> getNameInfo(const std::string &name, Value value) {
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
        "Unsupported result type for Heracles SDK Emitter");
    return failure();
  }
  poly_mod_degree = ring.getPolynomialModulus().getPolynomial().getDegree();
  if (auto rns = llvm::dyn_cast<rns::RNSType>(ring.getCoefficientType()))
    cur_rns_limbs = rns.getBasisTypes().size();

  return ValueNameInfo({name, is_ptxt, poly_mod_degree, cur_rns_limbs,
                        total_rns_terms, dimension});
}

std::string prettyName(const ValueNameInfo &info) {
  if (info.is_ptxt)
    return info.varname + "-" + std::to_string(info.dimension) + "-" +
           std::to_string(info.poly_mod_degree * info.cur_rns_limbs);
  return info.varname + "-" + std::to_string(info.dimension) + "-" +
         std::to_string(info.cur_rns_limbs);
};

}  // namespace heracles
}  // namespace heir
}  // namespace mlir

#include "lib/Analysis/NoiseAnalysis/BGV/Noise.h"

#include <cmath>

#include "llvm/include/llvm/Support/raw_ostream.h"  // from @llvm-project

namespace mlir {
namespace heir {
namespace bgv {

std::string NoiseState::toString() const {
  switch (noiseType) {
    case (NoiseType::UNINITIALIZED):
      return "NoiseState(uninitialized)";
    case (NoiseType::SET):
      return "NoiseState(" + std::to_string(log(getValue()) / log(2)) + ") ";
  }
}

llvm::raw_ostream &operator<<(llvm::raw_ostream &os, const NoiseState &noise) {
  return os << noise.toString();
}

Diagnostic &operator<<(Diagnostic &diagnostic, const NoiseState &noise) {
  return diagnostic << noise.toString();
}

}  // namespace bgv
}  // namespace heir
}  // namespace mlir

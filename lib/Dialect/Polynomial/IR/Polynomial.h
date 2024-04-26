#ifndef LIB_DIALECT_POLYNOMIAL_IR_POLYNOMIAL_H_
#define LIB_DIALECT_POLYNOMIAL_IR_POLYNOMIAL_H_

#include "llvm/include/llvm/ADT/APInt.h"         // from @llvm-project
#include "llvm/include/llvm/ADT/DenseMapInfo.h"  // from @llvm-project
#include "llvm/include/llvm/ADT/Hashing.h"       // from @llvm-project
#include "mlir/include/mlir/Support/LLVM.h"      // from @llvm-project

namespace mlir {

class MLIRContext;

namespace heir {
namespace polynomial {

constexpr unsigned APINT_BIT_WIDTH = 64;

namespace detail {
struct PolynomialStorage;
}  // namespace detail

class Monomial {
 public:
  Monomial(int64_t coeff, uint64_t expo)
      : coefficient(APINT_BIT_WIDTH, coeff), exponent(APINT_BIT_WIDTH, expo) {}

  Monomial(APInt coeff, APInt expo) : coefficient(coeff), exponent(expo) {}

  Monomial() : coefficient(APINT_BIT_WIDTH, 0), exponent(APINT_BIT_WIDTH, 0) {}

  bool operator==(Monomial other) const {
    return other.coefficient == coefficient && other.exponent == exponent;
  }
  bool operator!=(Monomial other) const {
    return other.coefficient != coefficient || other.exponent != exponent;
  }

  /// Monomials are ordered by exponent.
  bool operator<(const Monomial &other) const {
    return (exponent.ult(other.exponent));
  }

  // Prints polynomial to 'os'.
  void print(raw_ostream &os) const;

  friend ::llvm::hash_code hash_value(Monomial arg);

 public:
  APInt coefficient;

  // Always unsigned
  APInt exponent;
};

/// A single-variable polynomial with integer coefficients. Polynomials are
/// immutable and uniqued.
///
/// Eg: x^1024 + x + 1
///
/// The symbols used as the polynomial's indeterminate don't matter, so long as
/// it is used consistently throughout the polynomial.
class Polynomial {
 public:
  using ImplType = detail::PolynomialStorage;

  constexpr Polynomial() = default;
  explicit Polynomial(ImplType *terms) : terms(terms) {}

  static Polynomial fromMonomials(ArrayRef<Monomial> monomials,
                                  MLIRContext *context);
  /// Returns a polynomial with coefficients given by `coeffs`
  static Polynomial fromCoefficients(ArrayRef<int64_t> coeffs,
                                     MLIRContext *context);

  MLIRContext *getContext() const;

  explicit operator bool() const { return terms != nullptr; }
  bool operator==(Polynomial other) const { return other.terms == terms; }
  bool operator!=(Polynomial other) const { return !(other.terms == terms); }

  // Prints polynomial to 'os'.
  void print(raw_ostream &os) const;
  void print(raw_ostream &os, const std::string &separator,
             const std::string &exponentiation) const;
  void dump() const;

  // Prints polynomial so that it can be used as a valid identifier
  std::string toIdentifier() const;

  // A polynomial's terms are canonically stored in order of increasing degree.
  ArrayRef<Monomial> getTerms() const;

  unsigned getDegree() const;

  friend ::llvm::hash_code hash_value(Polynomial arg);

 private:
  ImplType *terms{nullptr};
};

// Make Polynomial hashable.
inline ::llvm::hash_code hash_value(Polynomial arg) {
  return ::llvm::hash_value(arg.terms);
}

inline ::llvm::hash_code hash_value(Monomial arg) {
  return ::llvm::hash_value(arg.coefficient) ^ ::llvm::hash_value(arg.exponent);
}

inline raw_ostream &operator<<(raw_ostream &os, Polynomial polynomial) {
  polynomial.print(os);
  return os;
}

}  // namespace polynomial
}  // namespace heir
}  // namespace mlir

namespace llvm {

// Polynomials hash just like pointers
template <>
struct DenseMapInfo<mlir::heir::polynomial::Polynomial> {
  static mlir::heir::polynomial::Polynomial getEmptyKey() {
    auto *pointer = llvm::DenseMapInfo<void *>::getEmptyKey();
    return mlir::heir::polynomial::Polynomial(
        static_cast<mlir::heir::polynomial::Polynomial::ImplType *>(pointer));
  }
  static mlir::heir::polynomial::Polynomial getTombstoneKey() {
    auto *pointer = llvm::DenseMapInfo<void *>::getTombstoneKey();
    return mlir::heir::polynomial::Polynomial(
        static_cast<mlir::heir::polynomial::Polynomial::ImplType *>(pointer));
  }
  static unsigned getHashValue(mlir::heir::polynomial::Polynomial val) {
    return mlir::heir::polynomial::hash_value(val);
  }
  static bool isEqual(mlir::heir::polynomial::Polynomial LHS,
                      mlir::heir::polynomial::Polynomial RHS) {
    return LHS == RHS;
  }
};

}  // namespace llvm

#endif  // LIB_DIALECT_POLYNOMIAL_IR_POLYNOMIAL_H_

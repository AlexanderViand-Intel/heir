// Example of a high-level input program
// See https://github.com/google/heir/pull/467 for information on
// how to use Polygeist (the MLIR C/C++ frontend) to convert this.
// Note: C/C++ --> MLIR is still very much WIP.

#include <vector>

/// shorten std::vector<T> for slides
template <typename T>
using v = std::vector<T>;

v<int> foo(v<int> x, v<int> y) {
  for (int i = 0; i < 8; ++i) {
    int x2 = x[i] * x[i];
    int y2 = y[i] * y[i];
    y[i] = x2 - y2;
  }
  return y;
}

// Python and Python-like Frontend Alternatives: MLL, Nelli or xDSL-Frontend

// MLL was developed as a python-like DSL builder for MLIR Intel,
//  but the associated project was cut and the  project is now abanonwware.
//  See https://github.com/imv1990/mll/tree/mll/mll
// and https://discourse.llvm.org/t/mll-an-extensible-front-end-for-mlir/65770

// Nelli is a similar project, but more focused towards replicating MLIR
// directly

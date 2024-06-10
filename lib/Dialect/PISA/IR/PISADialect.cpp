#include "lib/Dialect/PISA/IR/PISADialect.h"

#include "mlir/include/mlir/IR/DialectImplementation.h"  // from @llvm-project

// NOLINTNEXTLINE(misc-include-cleaner): Required to define PISAOps

#include "lib/Dialect/PISA/IR/PISAAttributes.h"
#include "lib/Dialect/PISA/IR/PISAOps.h"
#include "lib/Dialect/PISA/IR/PISATypes.h"

// Generated definitions
#include "lib/Dialect/PISA/IR/PISADialect.cpp.inc"

#define GET_ATTRDEF_CLASSES
#include "lib/Dialect/PISA/IR/PISAAttributes.cpp.inc"

#define GET_TYPEDEF_CLASSES
#include "lib/Dialect/PISA/IR/PISATypes.cpp.inc"

#define GET_OP_CLASSES
#include "lib/Dialect/PISA/IR/PISAOps.cpp.inc"

namespace mlir {
namespace heir {
namespace pisa {

void PISADialect::initialize() {
  addAttributes<
#define GET_ATTRDEF_LIST
#include "lib/Dialect/PISA/IR/PISAAttributes.cpp.inc"
      >();

  addTypes<
#define GET_TYPEDEF_LIST
#include "lib/Dialect/PISA/IR/PISATypes.cpp.inc"
      >();

  addOperations<
#define GET_OP_LIST
#include "lib/Dialect/PISA/IR/PISAOps.cpp.inc"
      >();
}

}  // namespace pisa
}  // namespace heir
}  // namespace mlir

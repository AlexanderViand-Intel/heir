include_guard()

# Make MLIR/LLVM CMake helper functions available
list(APPEND CMAKE_MODULE_PATH "${MLIR_CMAKE_DIR}")
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddMLIR)
include(AddLLVM)
include(TableGen)

# custom helper for HEIR Dialects that follow our naming conventions
# This effectively behaves like a combination of add_mlir_dialect (tablegen
# and add_mlir_dialect_library (C++ library) from MLIR's AddMLIR.cmake module
#
# In addition to the explicit arguments, it takes the usual syntax of add_mlir_library
# and forwards them to add_mlir_dialect_library. TODO (build): create custom macros instead
#
# While it's generally a really bad idea to try and "forward" arguments to a CMake macro
# (bad things happen to lists, see https://gitlab.kitware.com/cmake/cmake/-/issues/22157),
# the MLIR/LLVM macros already do this internally quite a bit so it should be safe to do
# unless something changes with the macros in AddMLIR.cmake / AddLLVM.cmake upstream
function(add_AUTOMAGIC_heir_dialect dialect_name dialect_namespace)

  ### TableGen

  # TableGen target
  add_custom_target(HEIR_Dialect_${dialect_name}_AllIncGen)

  # Main Dialect definition
  set(LLVM_TARGET_DEFINITIONS ${dialect_name}Dialect.td)
  mlir_tablegen(${dialect_name}Dialect.h.inc -gen-dialect-decls -dialect=${dialect_namespace})
  mlir_tablegen(${dialect_name}Dialect.cpp.inc -gen-dialect-defs -dialect=${dialect_namespace})
  add_public_tablegen_target(HEIR_Dialect_${dialect_name}_DialectIncGen)
  add_dependencies(HEIR_Dialect_${dialect_name}_AllIncGen HEIR_Dialect_${dialect_name}_DialectIncGen)

  # Ops
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect_name}Ops.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}Ops.td)
    mlir_tablegen(${dialect_name}Ops.h.inc -gen-op-decls -dialect=${dialect_namespace})
    mlir_tablegen(${dialect_name}Ops.cpp.inc -gen-op-defs -dialect=${dialect_namespace})
    add_public_tablegen_target(HEIR_Dialect_${dialect_name}_OpsIncGen)
    add_dependencies(HEIR_Dialect_${dialect_name}_AllIncGen HEIR_Dialect_${dialect_name}_OpsIncGen)
  endif()

  # Types
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect_name}Types.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}Types.td)
    mlir_tablegen(${dialect_name}Types.h.inc -gen-typedef-decls -dialect=${dialect_namespace})
    mlir_tablegen(${dialect_name}Types.cpp.inc -gen-typedef-defs -dialect=${dialect_namespace})
    add_public_tablegen_target(HEIR_Dialect_${dialect_name}_TypesIncGen)
    add_dependencies(HEIR_Dialect_${dialect_name}_AllIncGen HEIR_Dialect_${dialect_name}_TypesIncGen)
  endif()

  # Attributes
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect_name}Attributes.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}Attributes.td)
    mlir_tablegen(${dialect_name}Attributes.h.inc -gen-attrdef-decls -attrdefs-dialect=${dialect_namespace})
    mlir_tablegen(${dialect_name}Attributes.cpp.inc -gen-attrdef-defs -attrdefs-dialect=${dialect_namespace})
    add_public_tablegen_target(HEIR_Dialect_${dialect_name}_AttributesIncGen)
    add_dependencies(HEIR_Dialect_${dialect_name}_AllIncGen HEIR_Dialect_${dialect_name}_AttributesIncGen)
  endif()

  #Enums
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect_name}Enums.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}Enums.td)
    mlir_tablegen(${dialect_name}Enums.h.inc -gen-enum-decls)
    mlir_tablegen(${dialect_name}Enums.cpp.inc -gen-enum-defs)
    add_public_tablegen_target(HEIR_Dialect_${dialect_name}_EnumsIncGen)
    add_dependencies(HEIR_Dialect_${dialect_name}_AllIncGen HEIR_Dialect_${dialect_name}_EnumsIncGen)
  #Enums (but from Attributes file) #TODO (build): Deprecate this pattern
  elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect_name}Attributes.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}Attributes.td)
    mlir_tablegen(${dialect_name}Enums.h.inc -gen-enum-decls)
    mlir_tablegen(${dialect_name}Enums.cpp.inc -gen-enum-defs)
    add_public_tablegen_target(HEIR_Dialect_${dialect_name}_EnumsIncGen)
    add_dependencies(HEIR_Dialect_${dialect_name}_AllIncGen HEIR_Dialect_${dialect_name}_EnumsIncGen)
  endif()

  # Type Interfaces
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect_name}TypeInterfaces.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect_name}TypeInterfaces.td)
    mlir_tablegen(${dialect_name}TypeInterfaces.h.inc -gen-type-interface-decls -name ${dialect_namespace})
    mlir_tablegen(${dialect_name}TypeInterfaces.cpp.inc -gen-type-interface-defs -name ${dialect_namespace})
    add_public_tablegen_target(HEIR_Dialect_${dialect_name}_TypeInterfacesIncGen)
    add_dependencies(HEIR_Dialect_${dialect_name}_AllIncGen HEIR_Dialect_${dialect_name}_TypeInterfacesIncGen)
  endif()

  #### C++ Library

  # Strip the namespace from the argument list, as it's not expected by add_mlir_dialect_library
  set(args ${ARGV})
  list(REMOVE_AT args 1)

  # Prepend "heir__Dialect__" to the target name
  list(REMOVE_AT args 0)
  list(INSERT args 0 "HEIR_Dialect_${dialect_name}")

  add_mlir_dialect_library(${args})

  add_dependencies(HEIR_Dialect_${dialect_name} HEIR_Dialect_${dialect_name}_AllIncGen)

endfunction() # add_heir_dialect


# custom TableGen helper for HEIR Dialects that follow our naming conventions
function(add_heir_dialect dialect dialect_namespace)
  add_custom_target(HEIR${dialect}IncGen)

  set(LLVM_TARGET_DEFINITIONS ${dialect}Dialect.td)
  mlir_tablegen(${dialect}Dialect.h.inc -gen-dialect-decls -dialect=${dialect_namespace})
  mlir_tablegen(${dialect}Dialect.cpp.inc -gen-dialect-defs -dialect=${dialect_namespace})
  add_public_tablegen_target(HEIR${dialect}DialectIncGen)
  add_dependencies(HEIR${dialect}IncGen HEIR${dialect}DialectIncGen)

  # Ops
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Ops.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect}Ops.td)
    mlir_tablegen(${dialect}Ops.h.inc -gen-op-decls -dialect=${dialect_namespace})
    mlir_tablegen(${dialect}Ops.cpp.inc -gen-op-defs -dialect=${dialect_namespace})
    add_public_tablegen_target(HEIR${dialect}OpsIncGen)
    add_dependencies(HEIR${dialect}IncGen HEIR${dialect}OpsIncGen)
  endif()

  # Types
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Types.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect}Types.td)
    mlir_tablegen(${dialect}Types.h.inc -gen-typedef-decls -dialect=${dialect_namespace})
    mlir_tablegen(${dialect}Types.cpp.inc -gen-typedef-defs -dialect=${dialect_namespace})
    add_public_tablegen_target(HEIR${dialect}TypesIncGen)
    add_dependencies(HEIR${dialect}IncGen HEIR${dialect}TypesIncGen)
  endif()

  # Attributes
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Attributes.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect}Attributes.td)
    mlir_tablegen(${dialect}Attributes.h.inc -gen-attrdef-decls -attrdefs-dialect=${dialect_namespace})
    mlir_tablegen(${dialect}Attributes.cpp.inc -gen-attrdef-defs -attrdefs-dialect=${dialect_namespace})
    add_public_tablegen_target(HEIR${dialect}AttributesIncGen)
    add_dependencies(HEIR${dialect}IncGen HEIR${dialect}AttributesIncGen)
  endif()

  #Enums
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Enums.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect}Enums.td)
    mlir_tablegen(${dialect}Enums.h.inc -gen-enum-decls)
    mlir_tablegen(${dialect}Enums.cpp.inc -gen-enum-defs)
    add_public_tablegen_target(HEIR${dialect}EnumsIncGen)
    add_dependencies(HEIR${dialect}IncGen HEIR${dialect}EnumsIncGen)
  #Enums (but from Attributes file)
  elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Attributes.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect}Attributes.td)
    mlir_tablegen(${dialect}Enums.h.inc -gen-enum-decls)
    mlir_tablegen(${dialect}Enums.cpp.inc -gen-enum-defs)
    add_public_tablegen_target(HEIR${dialect}EnumsIncGen)
    add_dependencies(HEIR${dialect}IncGen HEIR${dialect}EnumsIncGen)
  endif()

  # Type Interfaces
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dialect}TypeInterfaces.td")
    set(LLVM_TARGET_DEFINITIONS ${dialect}TypeInterfaces.td)
    mlir_tablegen(${dialect}TypeInterfaces.h.inc -gen-type-interface-decls -name ${dialect_namespace})
    mlir_tablegen(${dialect}TypeInterfaces.cpp.inc -gen-type-interface-defs -name ${dialect_namespace})
    add_public_tablegen_target(HEIR${dialect}TypeInterfacesIncGen)
    add_dependencies(HEIR${dialect}IncGen HEIR${dialect}TypeInterfacesIncGen)
  endif()

endfunction() # add_heir_dialect


# custom TableGen helper for HEIR passes
# call add_heir_pass(someName) for normal use
# call add_heir_pass(someName PATTERNS) to generate rewriter patterns
function(add_heir_pass pass)
  set(LLVM_TARGET_DEFINITIONS ${pass}.td)
  mlir_tablegen(${pass}.h.inc -gen-pass-decls -name ${pass})

  if(ARGN MATCHES "PATTERNS")
    mlir_tablegen(${pass}.cpp.inc -gen-rewriters)
  endif()

  add_public_tablegen_target(HEIR${pass}IncGen)
endfunction() # add_heir_pass


## TODO: INTEGRATE THIS
# target_compile_features(my_lib PUBLIC cxx_std_17)
# if(CMAKE_CXX_STANDARD LESS 17)
#   message(FATAL_ERROR
#       "my_lib_project requires CMAKE_CXX_STANDARD >= 17 (got: ${CMAKE_CXX_STANDARD})")
# endif()

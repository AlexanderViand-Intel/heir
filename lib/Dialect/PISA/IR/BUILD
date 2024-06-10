# PISA dialect implementation

load("@llvm-project//mlir:tblgen.bzl", "gentbl_cc_library", "td_library")

package(
    default_applicable_licenses = ["@heir//:license"],
    default_visibility = ["//visibility:public"],
)

cc_library(
    name = "Dialect",
    srcs = [
        "PISADialect.cpp",
    ],
    hdrs = [
        "PISAAttributes.h",
        "PISADialect.h",
        "PISAOps.h",
        "PISATypes.h",
    ],
    deps = [
        "attributes_inc_gen",
        "dialect_inc_gen",
        "ops_inc_gen",
        "types_inc_gen",
        ":PISAAttributes",
        ":PISAOps",
        ":PISATypes",
        "@llvm-project//llvm:Support",
        "@llvm-project//mlir:IR",
    ],
)

cc_library(
    name = "PISAAttributes",
    srcs = [
        "PISAAttributes.cpp",
    ],
    hdrs = [
        "PISAAttributes.h",
        "PISADialect.h",
    ],
    deps = [
        ":attributes_inc_gen",
        ":dialect_inc_gen",
        "@llvm-project//mlir:IR",
    ],
)

cc_library(
    name = "PISATypes",
    srcs = [
        "PISATypes.cpp",
    ],
    hdrs = [
        "PISAAttributes.h",
        "PISADialect.h",
        "PISATypes.h",
    ],
    deps = [
        ":PISAAttributes",
        ":dialect_inc_gen",
        ":ops_inc_gen",
        ":types_inc_gen",
        "@llvm-project//mlir:IR",
    ],
)

cc_library(
    name = "PISAOps",
    srcs = [
        "PISAOps.cpp",
    ],
    hdrs = [
        "PISADialect.h",
        "PISAOps.h",
        "PISATypes.h",
    ],
    deps = [
        ":PISAAttributes",
        ":PISATypes",
        ":dialect_inc_gen",
        ":ops_inc_gen",
        ":types_inc_gen",
        "@llvm-project//llvm:Support",
        "@llvm-project//mlir:ArithDialect",
        "@llvm-project//mlir:IR",
        "@llvm-project//mlir:InferTypeOpInterface",
        "@llvm-project//mlir:Support",
    ],
)

td_library(
    name = "td_files",
    srcs = [
        "PISAAttributes.td",
        "PISADialect.td",
        "PISAOps.td",
        "PISATypes.td",
    ],
    # include from the heir-root to enable fully-qualified include-paths
    includes = ["../../../.."],
    deps = [
        "@heir//lib/DRR",
        "@llvm-project//mlir:BuiltinDialectTdFiles",
        "@llvm-project//mlir:InferTypeOpInterfaceTdFiles",
        "@llvm-project//mlir:OpBaseTdFiles",
        "@llvm-project//mlir:SideEffectInterfacesTdFiles",
    ],
)

gentbl_cc_library(
    name = "dialect_inc_gen",
    tbl_outs = [
        (
            [
                "-gen-dialect-decls",
            ],
            "PISADialect.h.inc",
        ),
        (
            [
                "-gen-dialect-defs",
            ],
            "PISADialect.cpp.inc",
        ),
    ],
    tblgen = "@llvm-project//mlir:mlir-tblgen",
    td_file = "PISADialect.td",
    deps = [
        ":td_files",
    ],
)

gentbl_cc_library(
    name = "attributes_inc_gen",
    tbl_outs = [
        (
            [
                "-gen-attrdef-decls",
            ],
            "PISAAttributes.h.inc",
        ),
        (
            [
                "-gen-attrdef-defs",
            ],
            "PISAAttributes.cpp.inc",
        ),
        (
            ["-gen-attrdef-doc"],
            "PISAAttributes.md",
        ),
    ],
    tblgen = "@llvm-project//mlir:mlir-tblgen",
    td_file = "PISAAttributes.td",
    deps = [
        ":dialect_inc_gen",
        ":td_files",
    ],
)

gentbl_cc_library(
    name = "types_inc_gen",
    tbl_outs = [
        (
            [
                "-gen-typedef-decls",
            ],
            "PISATypes.h.inc",
        ),
        (
            [
                "-gen-typedef-defs",
            ],
            "PISATypes.cpp.inc",
        ),
        (
            ["-gen-typedef-doc"],
            "PISATypes.md",
        ),
    ],
    tblgen = "@llvm-project//mlir:mlir-tblgen",
    td_file = "PISATypes.td",
    deps = [
        ":attributes_inc_gen",
        ":dialect_inc_gen",
        ":td_files",
    ],
)

gentbl_cc_library(
    name = "ops_inc_gen",
    tbl_outs = [
        (
            ["-gen-op-decls"],
            "PISAOps.h.inc",
        ),
        (
            ["-gen-op-defs"],
            "PISAOps.cpp.inc",
        ),
        (
            ["-gen-op-doc"],
            "PISAOps.md",
        ),
    ],
    tblgen = "@llvm-project//mlir:mlir-tblgen",
    td_file = "PISAOps.td",
    deps = [
        ":dialect_inc_gen",
        ":td_files",
        ":types_inc_gen",
    ],
)

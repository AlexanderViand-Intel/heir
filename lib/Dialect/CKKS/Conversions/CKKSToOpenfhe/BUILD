load("@llvm-project//mlir:tblgen.bzl", "gentbl_cc_library")

package(
    default_applicable_licenses = ["@heir//:license"],
    default_visibility = ["//visibility:public"],
)

cc_library(
    name = "CKKSToOpenfhe",
    srcs = ["CKKSToOpenfhe.cpp"],
    hdrs = [
        "CKKSToOpenfhe.h",
    ],
    deps = [
        ":pass_inc_gen",
        "@heir//lib/Dialect/CKKS/IR:Dialect",
        "@heir//lib/Dialect/LWE/Conversions/LWEToOpenfhe",
        "@heir//lib/Dialect/LWE/Conversions/RlweToOpenfhe",
        "@heir//lib/Dialect/LWE/IR:Dialect",
        "@heir//lib/Dialect/LWE/IR:Patterns",
        "@heir//lib/Dialect/Openfhe/IR:Dialect",
        "@heir//lib/Utils/ConversionUtils",
        "@llvm-project//mlir:FuncDialect",
        "@llvm-project//mlir:IR",
        "@llvm-project//mlir:Pass",
        "@llvm-project//mlir:Support",
        "@llvm-project//mlir:TransformUtils",
    ],
)

gentbl_cc_library(
    name = "pass_inc_gen",
    tbl_outs = [
        (
            [
                "-gen-pass-decls",
                "-name=CKKSToOpenfhe",
            ],
            "CKKSToOpenfhe.h.inc",
        ),
        (
            ["-gen-pass-doc"],
            "CKKSToOpenfhe.md",
        ),
    ],
    tblgen = "@llvm-project//mlir:mlir-tblgen",
    td_file = "CKKSToOpenfhe.td",
    deps = [
        "@llvm-project//mlir:OpBaseTdFiles",
        "@llvm-project//mlir:PassBaseTdFiles",
    ],
)

load("@llvm-project//mlir:tblgen.bzl", "gentbl_cc_library")

package(
    default_applicable_licenses = ["@heir//:license"],
    default_visibility = ["//visibility:public"],
)

cc_library(
    name = "BGVToLattigo",
    srcs = ["BGVToLattigo.cpp"],
    hdrs = [
        "BGVToLattigo.h",
    ],
    deps = [
        ":pass_inc_gen",
        "@heir//lib/Dialect/BGV/IR:Dialect",
        # "@heir//lib/Dialect/LWE/Conversions/LWEToLattigo",
        "@heir//lib/Dialect/LWE/Conversions/RlweToLattigo",
        "@heir//lib/Dialect/LWE/IR:Dialect",
        "@heir//lib/Dialect/Lattigo/IR:Dialect",
        "@heir//lib/Utils",
        "@heir//lib/Utils:ConversionUtils",
        "@llvm-project//mlir:FuncDialect",
        "@llvm-project//mlir:IR",
        "@llvm-project//mlir:Pass",
        "@llvm-project//mlir:Support",
        "@llvm-project//mlir:TensorDialect",
        "@llvm-project//mlir:TransformUtils",
    ],
)

gentbl_cc_library(
    name = "pass_inc_gen",
    tbl_outs = [
        (
            [
                "-gen-pass-decls",
                "-name=BGVToLattigo",
            ],
            "BGVToLattigo.h.inc",
        ),
        (
            ["-gen-pass-doc"],
            "BGVToLattigo.md",
        ),
    ],
    tblgen = "@llvm-project//mlir:mlir-tblgen",
    td_file = "BGVToLattigo.td",
    deps = [
        "@llvm-project//mlir:OpBaseTdFiles",
        "@llvm-project//mlir:PassBaseTdFiles",
    ],
)

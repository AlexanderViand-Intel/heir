# SecretnessAnalysis analysis class
package(
    default_applicable_licenses = ["@heir//:license"],
    default_visibility = ["//visibility:public"],
)

cc_library(
    name = "SecretnessAnalysis",
    srcs = ["SecretnessAnalysis.cpp"],
    hdrs = ["SecretnessAnalysis.h"],
    deps = [
        "@heir//lib/Dialect/Secret/IR:Dialect",
        "@llvm-project//mlir:Analysis",
        "@llvm-project//mlir:FuncDialect",
        "@llvm-project//mlir:IR",
        "@llvm-project//mlir:Support",
    ],
)

"""Approximation utilities"""

package(
    default_applicable_licenses = ["@heir//:license"],
    default_visibility = ["//visibility:public"],
)

cc_library(
    name = "Chebyshev",
    srcs = ["Chebyshev.cpp"],
    hdrs = ["Chebyshev.h"],
    deps = [
        "@heir//lib/Utils/Polynomial",
        "@llvm-project//llvm:Support",
        "@llvm-project//mlir:Support",
    ],
)

cc_test(
    name = "ChebyshevTest",
    srcs = ["ChebyshevTest.cpp"],
    deps = [
        ":Chebyshev",
        "@googletest//:gtest_main",
        "@heir//lib/Utils/Polynomial",
        "@llvm-project//llvm:Support",
        "@llvm-project//mlir:Support",
    ],
)

load("@rules_cc//cc:defs.bzl", "cc_library", "cc_proto_library")
load("@rules_proto//proto:defs.bzl", "proto_library")

package(
    default_visibility = ["//visibility:public"],
    features = [
    ],
)

licenses(["notice"])

proto_library(
    name = "common_proto",
    srcs = ["src/data_formats/proto/heracles/common.proto"],
    strip_import_prefix = "src/data_formats/proto/heracles",
    deps = ["@com_google_protobuf//:descriptor_proto"],
)

cc_proto_library(
    name = "common_cc_proto",
    deps = [":common_proto"],
)

cc_library(
    name = "common_cc_proto_path_fixed",
    hdrs = [":common_cc_proto"],
    include_prefix = "heracles/proto",
    includes = ["."],
    strip_include_prefix = "_virtual_imports/common_proto",
    deps = [":common_cc_proto"],
)

proto_library(
    name = "data_proto",
    srcs = ["src/data_formats/proto/heracles/data.proto"],
    strip_import_prefix = "src/data_formats/proto/heracles",
    deps = [
        ":common_proto",
        "@com_google_protobuf//:descriptor_proto",
    ],
)

cc_proto_library(
    name = "data_cc_proto",
    deps = [":data_proto"],
)

cc_library(
    name = "data_cc_proto_path_fixed",
    hdrs = [":data_cc_proto"],
    include_prefix = "heracles/proto",
    includes = ["."],
    strip_include_prefix = "_virtual_imports/data_proto",
    deps = [":data_cc_proto"],
)

proto_library(
    name = "fhe_trace_proto",
    srcs = ["src/data_formats/proto/heracles/fhe_trace.proto"],
    strip_import_prefix = "src/data_formats/proto/heracles",
    deps = [
        ":common_proto",
        "@com_google_protobuf//:descriptor_proto",
    ],
)

cc_proto_library(
    name = "fhe_trace_cc_proto",
    deps = [":fhe_trace_proto"],
)

cc_library(
    name = "fhe_trace_cc_proto_path_fixed",
    hdrs = [":fhe_trace_cc_proto"],
    include_prefix = "heracles/proto",
    strip_include_prefix = "_virtual_imports/fhe_trace_proto",
    deps = [":fhe_trace_cc_proto"],
)

proto_library(
    name = "maps_proto",
    srcs = [
        "src/data_formats/proto/heracles/maps.proto",
    ],
    strip_import_prefix = "src/data_formats/proto/heracles",
    deps = [
        ":common_proto",
        "@com_google_protobuf//:descriptor_proto",
    ],
)

cc_proto_library(
    name = "maps_cc_proto",
    deps = [":maps_proto"],
)

cc_library(
    name = "maps_cc_proto_path_fixed",
    hdrs = [":maps_cc_proto"],
    include_prefix = "heracles/proto",
    strip_include_prefix = "_virtual_imports/maps_proto",
    deps = [":maps_cc_proto"],
)

cc_library(
    name = "core",
    srcs = glob([
        "src/data_formats/cpp/heracles/**/*.cpp",
    ]),
    hdrs = glob(["src/data_formats/cpp/include/**/*.h"]) + [
        "heracles/heracles_proto.h",
    ],
    includes = [
        "heracles/proto",
        "src/data_formats/cpp/include",
    ],
    deps = [
        ":common_cc_proto_path_fixed",
        ":data_cc_proto_path_fixed",
        ":fhe_trace_cc_proto_path_fixed",
        ":maps_cc_proto_path_fixed",
        "@com_google_protobuf//:protobuf",
    ],
)

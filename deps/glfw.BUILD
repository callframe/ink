load("@rules_cc//cc:defs.bzl", "cc_library")
load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")

filegroup(
    name = "glfw_srcs",
    srcs = glob(["**"]),
)

filegroup(
    name = "glfw_header_file",
    srcs = ["include/GLFW/glfw3.h"],
    visibility = ["//visibility:public"]
)

cc_library(
    name = "glfw_header",
    hdrs = [":glfw_header_file"],
    includes = ["include"],
    visibility = ["//visibility:public"],
)

UNIX_DEPS = select({
    "@platforms//os:windows": [],
    "@platforms//os:macos": [],
    "//conditions:default": [
        "@wayland//:scanner",
        # TODO: Decide whether to vendor xkbcommon
    ]
})

UNIX_ENV = select({
    "@platforms//os:windows": {},
    "@platforms//os:macos": {},
    "//conditions:default": {
        "PKG_CONFIG_PATH": "/usr/lib/pkgconfig:/usr/share/pkgconfig",
    },
})

UNIX_LINKOPTS = select({
    "@platforms//os:windows": [],
    "@platforms//os:macos": [],
    "//conditions:default": [
        "-lwayland-client",
        "-lwayland-cursor",
        "-lwayland-egl",
    ],
})

cmake(
    name = "glfw",
    lib_source = ":glfw_srcs",
    cache_entries = {
        "BUILD_SHARED_LIBS": "ON",
        "GLFW_BUILD_EXAMPLES": "OFF",
        "GLFW_BUILD_TESTS": "OFF",
        # We do not support x11
        "GLFW_BUILD_X11": "OFF",
    },
    out_interface_libs  = select({
        "@platforms//os:windows": ["glfw3dll.lib"],
        "//conditions:default": [],
    }),
    out_shared_libs = select({
        "@platforms//os:windows": ["glfw3.dll"],
        "@platforms//os:macos": ["libglfw.3.5.dylib"],
        "//conditions:default": ["libglfw.so.3"],
    }),
    env = UNIX_ENV,
    deps = UNIX_DEPS,
    linkopts = UNIX_LINKOPTS,
    visibility = ["//visibility:public"],
)

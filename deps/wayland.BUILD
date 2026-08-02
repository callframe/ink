load("@rules_foreign_cc//foreign_cc:defs.bzl", "meson")

filegroup(
    name = "wayland_srcs",
    srcs = glob(["**"]),
)

meson(
    name = "scanner",
    lib_source = ":wayland_srcs",
    options = {
        "libraries": "false",
        "scanner" : "true",
        "tests": "false",
        "documentation": "false",
        "dtd_validation": "false",
        "book": "false"
    },
    out_binaries = ["wayland-scanner"],
    visibility = ["//visibility:public"]
)

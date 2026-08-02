load("@rules_rust//rust/private:providers.bzl", "BuildInfo")

def _rust_out_dir_impl(ctx):
    out_dir = ctx.actions.declare_directory(ctx.label.name + ".out_dir")

    args = ctx.actions.args()
    args.add("--out-dir", out_dir.path)
    for src in ctx.files.srcs:
        name = ctx.attr.renames.get(src.basename, src.basename)
        args.add("--file", "{}={}".format(name, src.path))

    ctx.actions.run(
        arguments = [args],
        executable = ctx.executable._builder,
        inputs = ctx.files.srcs,
        mnemonic = "RustSynthOutDir",
        outputs = [out_dir],
        progress_message = "Building synthetic OUT_DIR for %{label}",
    )

    return [
        DefaultInfo(files = depset([out_dir])),
        # Every field except compile_data is optional; rustc.bzl guards each
        # access. compile_data must be a depset even when empty.
        BuildInfo(
            compile_data = depset(),
            dep_env = None,
            flags = None,
            link_search_paths = None,
            linker_flags = None,
            out_dir = out_dir,
            rustc_env = None,
        ),
    ]

rust_out_dir = rule(
    implementation = _rust_out_dir_impl,
    attrs = {
        "renames": attr.string_dict(
            doc = "Maps a source basename to the name it takes inside OUT_DIR.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Files placed at the top level of the synthesized OUT_DIR.",
        ),
        "_builder": attr.label(
            cfg = "exec",
            default = "//tools:out_dir_builder",
            executable = True,
        ),
    },
    doc = "Provides BuildInfo carrying a synthetic OUT_DIR built from srcs.",
)

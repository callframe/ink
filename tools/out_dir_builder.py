"""Materialize a synthetic OUT_DIR from Bazel-produced files.

Invoked by the `rust_out_dir` rule. Deliberately Python rather than a shell
script so the same code path works under bash, cmd.exe and PowerShell.
"""

import argparse
import pathlib
import shutil


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-dir", required=True)
    parser.add_argument(
        "--file",
        action="append",
        default=[],
        metavar="NAME=PATH",
        help="Copy PATH into the OUT_DIR under the name NAME.",
    )
    args = parser.parse_args()

    out_dir = pathlib.Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    for spec in args.file:
        name, separator, source = spec.partition("=")
        if not separator:
            raise SystemExit(f"--file expects NAME=PATH, got {spec!r}")
        destination = out_dir / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)


if __name__ == "__main__":
    main()

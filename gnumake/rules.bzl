# Copyright 2024 github.com/zadlg
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@gnumake//gnumake:toolchain_info.bzl", "GNUMakeToolchainInfo")

"""Create symlinks for all source files.

  Arguments:
    ctx:
      Analysis context
    subdir:
      Subdirectory which will contain the symlinks.

  Returns:
    Artifact to the subdirectory.
"""

def _symlink_all_source_files(ctx: AnalysisContext, subdir: str = "srcs"):
    srcs = {}
    for src in ctx.attrs.srcs:
        srcs[src.short_path] = src

    return ctx.actions.symlinked_dir("srcs", srcs)

def _gnumake_impl(ctx: AnalysisContext):
    gnumake_bin = ctx.attrs._gnumake_toolchain[GNUMakeToolchainInfo].bin

    install_dir = ctx.actions.declare_output(ctx.attrs.install_prefix, dir = True)

    srcs_dir = _symlink_all_source_files(ctx)

    args = cmd_args()
    args.add(["-C", srcs_dir])
    args.add(cmd_args(cmd_args(install_dir.as_output()).relative_to(srcs_dir), format = "PREFIX={}"))
    args.add(ctx.attrs.args)

    ctx.actions.run(
        args,
        category = "gnumake",
        always_print_stderr = True,
        exe = gnumake_bin,
    )

    return [
        DefaultInfo(default_output = install_dir),
    ]

def _gnumake_attributes() -> dict[str, Attr]:
    return {
        "args": attrs.list(
            attrs.arg(),
            default = [],
            doc = """
    A list of arguments to forward to the call to GNUMake.
""",
        ),
        "compiler_flags": attrs.list(
            attrs.arg(),
            default = [],
            doc = """
    Flags to use when compiling.
""",
        ),
        "install_prefix": attrs.string(
            default = "__install__",
            doc = """
    Install prefix path, relative to where to install the result of the build.
This is passed an an argument to `make` as `PREFIX=<value>`.
""",
        ),
        "platform_compiler_flags": attrs.list(
            attrs.tuple(
                attrs.regex(),
                attrs.list(
                    attrs.arg(),
                    default = [],
                    doc = """
    Platform specific compiler flags. See `cxx_common.platform_compiler_flags_arg()` for more information.
""",
                ),
            ),
            default = [],
            doc = """
    Flags to use when compiling.
""",
        ),
        "srcs": attrs.list(
            attrs.source(),
            doc = """
    Input source.
""",
        ),
        "targets": attrs.list(
            attrs.string(),
            default = ["", "install"],
            doc = """
    A list of targets to produce.
""",
        ),
        "_gnumake_toolchain": attrs.default_only(
            attrs.toolchain_dep(
                default = "@gnumake//:gnumake",
                providers = [GNUMakeToolchainInfo],
            ),
            doc = """
    GNUMake toolchain.
""",
        ),
    }

gnumake = rule(
    impl = _gnumake_impl,
    attrs = _gnumake_attributes(),
)

load("@bazel_skylib//rules:diff_test.bzl", "diff_test")

def _generate_lockfile(ctx):
    output_file = ctx.actions.declare_file(ctx.label.name + ".lock.json")

    args = ctx.actions.args()

    args.add_all("-chart", ctx.files.chartfile)
    args.add("-output", output_file)

    ctx.actions.run(
        mnemonic = "HelmLockFile",
        executable = ctx.executable._helmlock,
        arguments = [args],
        inputs = ctx.files.chartfile,
        outputs = [output_file],
    )

    return [
         DefaultInfo(files = depset([output_file])),
    ]

generate_lockfile = rule(
    implementation = _generate_lockfile,
    attrs = {
        "chartfile": attr.label(allow_files = [".yaml"]),
        "_helmlock": attr.label(
            executable=True,
            cfg = "exec",
            default="//cmd/helmlock"
        ),
    },
)


def lockfile(name, chart_file, lock_file):

    generate_lockfile(
        name=name,
        chartfile=chart_file
    )

    diff_test(
        name=name + ".test",
        file1=lock_file,
        file2=":"+name,
        failure_message="Diff detected, regenerate lock file",
    )
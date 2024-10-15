const std = @import("std");
const gitVersionTag = @import("src/gitversiontag.zig").gitVersionTag;

pub fn build(b: *std.Build) void {
    // write src/version.zig
    const alloc = std.heap.page_allocator;
    const gvs = gitVersionTag(alloc);
    const efmt = "WARNING: could not write src/version.zig:\n   {!}\n";
    if (std.fs.cwd().createFile("src/version.zig", .{})) |file| {
        defer file.close();
        const zigfmt = "pub const version_string = \"{s}\";";
        if (std.fmt.allocPrint(alloc, zigfmt, .{gvs})) |strline| {
            if (file.writeAll(strline)) {} else |e| {
                std.io.getStdErr().writer().print(efmt, .{e}) catch unreachable;
            }
        } else |err| {
            std.io.getStdErr().writer().print(efmt, .{err}) catch unreachable;
        }
    } else |err| {
        std.io.getStdErr().writer().print(efmt, .{err}) catch unreachable;
    }

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "vib",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const short_mod = b.addModule("short", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const exe = b.addExecutable(.{
        .name = "short",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "short", .module = short_mod },
            },
        }),
    });
    exe.root_module.linkSystemLibrary("pcre2-8", .{});
    exe.root_module.linkSystemLibrary("sqlite3", .{});
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the short CLI");
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_step.dependOn(&run_cmd.step);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const smoke_mod = b.createModule(.{
        .root_source_file = b.path("tests/smoke.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "short", .module = short_mod },
        },
    });
    const smoke_tests = b.addTest(.{
        .root_module = smoke_mod,
    });
    smoke_tests.root_module.linkSystemLibrary("pcre2-8", .{});
    smoke_tests.root_module.linkSystemLibrary("sqlite3", .{});
    const run_smoke_tests = b.addRunArtifact(smoke_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_smoke_tests.step);
}

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Zig module
    const czrex = b.addModule("czrex", .{
        .root_source_file = b.path("src/lib.zig"),
    });

    const lib = b.addStaticLibrary(.{
        .name = "czrexcc",
        .target = target,
        .optimize = optimize,
    });

    lib.linkLibCpp();

    b.installArtifact(lib);

    lib.addCSourceFile(.{
        .file = b.path("src/wrap.cpp"),
        .flags = &.{
            "-Xclang=-fwchar-type=int",
            "-Xclang=-fno-signed-wchar",
        },
    });

    czrex.linkLibrary(lib);

    const tests = b.addTest(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests.root_module.addImport("regex", czrex);

    const run_lib_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_lib_tests.step);
}

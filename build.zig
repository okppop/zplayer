const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // const optimize = std.builtin.OptimizeMode.ReleaseFast;

    const core = b.addLibrary(.{
        .name = "core",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/core/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const platform = b.addLibrary(.{
        .name = "platform",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/platform/root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    platform.root_module.addImport(core.name, core.root_module);
    platform.root_module.linkSystemLibrary("SDL3", .{});

    const medie = b.addLibrary(.{
        .name = "media",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/media/root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    medie.root_module.addImport(core.name, core.root_module);
    medie.root_module.linkSystemLibrary("avformat", .{});
    medie.root_module.linkSystemLibrary("avcodec", .{});
    medie.root_module.linkSystemLibrary("avutil", .{});

    const exe = b.addExecutable(.{
        .name = "zplayer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            // .optimize = std.builtin.OptimizeMode.ReleaseFast,
            .optimize = optimize,
        }),
    });
    exe.root_module.addImport(core.name, core.root_module);
    exe.root_module.addImport(platform.name, platform.root_module);
    exe.root_module.addImport(medie.name, medie.root_module);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run medie player");
    run_step.dependOn(&run_cmd.step);
}

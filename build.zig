const std = @import("std");
const io = @import("src/lib/io.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const freq_path = "src/lib/frequency.zig";
    _ = std.fs.cwd().statFile(freq_path) catch {
        const freq = try io.frequencyTableFrom("data/shakespeare.txt");
        try io.exportFrequencyTableToFile(freq_path, freq);
    };

    var challenge_dir = try std.fs.cwd().openDir("src/", .{ .iterate = true });
    var iterator = challenge_dir.iterate();
    while (try iterator.next()) |file| {
        if (file.kind != .file) {
            continue;
        }

        var buf: [256]u8 = undefined;
        const name = file.name[0 .. file.name.len - 4];
        const str_id = name[name.len - 2 ..];
        const id = try std.fmt.parseUnsigned(u32, str_id, 10);
        const full_path = try std.fmt.bufPrint(&buf, "src/{s}", .{file.name});
        const exe = b.addExecutable(.{
            .name = name,
            .root_source_file = b.path(full_path),
            .target = target,
            .optimize = optimize,
        });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);

        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const cmd_info = try std.fmt.bufPrint(&buf, "Run challenge {d}", .{id});
        const run_step = b.step(name, cmd_info);
        run_step.dependOn(&run_cmd.step);
    }

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/lib/tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

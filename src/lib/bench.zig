const std = @import("std");

pub fn benchmark(f: fn () anyerror!void) !void {
    const start = std.time.milliTimestamp();
    defer {
        const end = std.time.milliTimestamp();
        std.debug.print("took: {} ms", .{end - start});
    }
    try f();
}

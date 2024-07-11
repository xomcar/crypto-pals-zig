const std = @import("std");
const chals = @import("chals.zig");
const opts = @import("frequency");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len != 2) {
        std.debug.print("Usage: {s} challenge_#\n", .{args[0]});
        return error.InvalidArgs;
    }
    const chal = try std.fmt.parseInt(usize, args[1], 10);
    switch (chal) {
        1 => {
            try chals.c1.solve();
        },
        2 => {
            try chals.c2.solve();
        },
        3 => {
            try chals.c3.solve();
        },
        else => {
            return error.InvalidParam;
        },
    }
}

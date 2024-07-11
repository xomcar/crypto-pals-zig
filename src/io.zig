const std = @import("std");

pub fn frequency_table_from(filename: []const u8) ![256]f32 {
    const data_file = try std.fs.cwd().openFile(filename, .{});
    var buffer: [1]u8 = undefined;
    var freqs = std.mem.zeroes([256]f32);
    var read: usize = 1;
    var sum: f32 = 0.0;
    while (read != 0) {
        read = try data_file.read(&buffer);
        const c = buffer[0];
        if ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z')) {
            freqs[c] += 1.0;
            sum += 1.0;
        }
    }
    for (&freqs) |*f| {
        f.* /= sum;
    }
    defer data_file.close();
    return freqs;
}

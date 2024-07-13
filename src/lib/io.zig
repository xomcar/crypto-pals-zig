const std = @import("std");

pub fn frequencyTableFrom(filename: []const u8) ![256]f32 {
    const data_file = try std.fs.cwd().openFile(filename, .{});
    defer data_file.close();
    var buffer: [1]u8 = undefined;
    var buf_reader = std.io.bufferedReader(data_file.reader());
    var freqs = std.mem.zeroes([256]f32);
    var read: usize = 1;
    var sum: f32 = 0.0;
    while (read != 0) {
        read = try buf_reader.read(&buffer);
        const c = buffer[0];
        if ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z')) {
            freqs[c] += 1.0;
            sum += 1.0;
        }
    }
    for (&freqs) |*f| {
        f.* /= sum;
    }
    return freqs;
}

pub fn exportFrequencyTableToFile(freq_path: []const u8, freqs: [256]f32) !void {
    const f = try std.fs.cwd().createFile(freq_path, .{});
    defer f.close();

    try f.writeAll("pub const freq : [256]f32 = .{\n");
    var buf: [256]u8 = undefined;
    for (freqs) |freq| {
        const str = try std.fmt.bufPrint(&buf, "    {d},\n", .{freq});
        try f.writeAll(str);
    }
    try f.writeAll("};\n");
}

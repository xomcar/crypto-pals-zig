const std = @import("std");

pub fn frequencyTableFromFile(filename: []const u8) ![256]f32 {
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
        freqs[c] += 1.0;
        sum += 1.0;
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
    var i: usize = 0;
    for (freqs) |freq| {
        const str = try std.fmt.bufPrint(&buf, "    {d}, //{}\n", .{ freq, i });
        i += 1;
        try f.writeAll(str);
    }
    try f.writeAll("};\n");
}

pub fn readMultilineFile(path: []const u8, a: std.mem.Allocator) ![]const u8 {
    const data_file = try std.fs.cwd().openFile(path, .{});
    var buffer: [1024]u8 = undefined;
    var data_buffer = try a.alloc(u8, (try data_file.stat()).size);
    const data_reader = data_file.reader();
    var data_buffer_index: usize = 0;
    while (try data_reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (line[line.len - 1] != '\r') {
            @memcpy(
                data_buffer[data_buffer_index .. data_buffer_index + line.len],
                line,
            );
            data_buffer_index += line.len;
        } else {
            @memcpy(
                data_buffer[data_buffer_index .. data_buffer_index + line.len - 1],
                line[0 .. line.len - 1],
            );
            data_buffer_index += line.len - 1;
        }
    }
    return try a.realloc(data_buffer, data_buffer_index);
}

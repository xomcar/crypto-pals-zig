const std = @import("std");
const xor = @import("lib/xor_cipher.zig");
const hex = @import("lib/hex.zig");
const base64 = @import("lib/base64.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    const data_file = try std.fs.cwd().openFile("data/6.txt", .{});
    var buffer: [1024]u8 = undefined;
    var data_buffer = try a.alloc(u8, (try data_file.stat()).size);
    defer a.free(data_buffer);
    const data_reader = data_file.reader();
    var data_buffer_index: usize = 0;
    while (try data_reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        @memcpy(data_buffer[data_buffer_index .. data_buffer_index + line.len], line);
        data_buffer_index += line.len;
    }
    const data = data_buffer[0..data_buffer_index];
    const hex_data = try base64.decode(data, a);
    defer a.free(hex_data);

    std.debug.print("{any}", .{base64.createDecodeTable()});
    const decoded_data = try hex.decode(hex_data, a);
    defer a.free(decoded_data);
    var best_dist: usize = std.math.maxInt(usize);
    var best_key_len: usize = 0;
    for (2..40) |key_len| {
        var norm_dist: usize = 0;
        for (0..4) |i| {
            const d = try xor.hammingDistance(decoded_data[2 * i .. 2 * i + key_len], decoded_data[2 * i + key_len .. 2 * i + (2 * key_len)]);
            norm_dist += d;
        }
        norm_dist /= key_len;
        norm_dist /= 4;
        if (best_dist < norm_dist) {
            best_key_len = key_len;
            best_dist = norm_dist;
        }
    }

    var buf = try a.alloc(u8, best_key_len);
    defer a.free(buf);
    var key = try a.alloc(u8, best_key_len);
    defer a.free(key);
    for (0..best_key_len) |n| {
        var data_index: usize = n;
        var buffer_index: usize = 0;
        while (data_index < data_buffer.len) : (data_index += best_key_len) {
            buf[buffer_index] = decoded_data[data_index];
            buffer_index += 1;
        }

        var best_candidate: u8 = 0;
        var min_dist = std.math.floatMax(f32);
        var candidate: u8 = 0;
        while (candidate < 255) : (candidate += 1) {
            const dec = try xor.applySingleKey(candidate, buf, a);
            defer a.free(dec);
            const d = xor.computeFrequencyAnalysis(dec);
            if (d < min_dist) {
                min_dist = d;
                best_candidate = candidate;
            }
        }

        key[n] = best_candidate;
    }
    std.debug.print("{s}\n", .{key});
}

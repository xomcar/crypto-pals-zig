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
    const data = data_buffer[0..data_buffer_index];
    const decoded_data = try base64.decode(data, a);
    defer a.free(decoded_data);
    var best_dist: f32 = std.math.floatMax(f32);
    var best_key_len: usize = 0;
    for (2..4) |key_len| {
        var dist: f32 = 0;
        std.debug.print("{any}\n", .{decoded_data[0 .. 8 * key_len]});
        var i: usize = 0;
        while (i < 2 * 4) : (i += 2 * key_len) {
            const word1 = decoded_data[i..][0..key_len];
            const word2 = decoded_data[i + key_len ..][0..key_len];
            std.debug.print("\t{any}\n\t{any}\n", .{ word1, word2 });
            const hamming_distance = try xor.hammingDistance(word1, word2);
            dist += @floatFromInt(hamming_distance);
        }
        const norm_dist: f32 = dist / 4 / @as(f32, @floatFromInt(key_len));
        std.debug.print("norm dist: {e:.3} len:{d:02}\n", .{
            norm_dist,
            key_len,
        });
        if (norm_dist < best_dist) {
            best_key_len = key_len;
            best_dist = norm_dist;
        }
    }
    std.debug.print("candidate best key length:\n\t{}\n", .{best_key_len});

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
    std.debug.print("{s} {d}\n", .{
        key,
        key,
    });
}

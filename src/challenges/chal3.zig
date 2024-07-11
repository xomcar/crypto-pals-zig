const std = @import("std");
const hex = @import("../hex.zig");
const xor = @import("../xor_cipher.zig");

pub fn solve() !void {
    const expected_text = "Cooking MC's like a pound of bacon";
    const expected_key: u8 = 88;
    const input_hex = "1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const input_bytes = try hex.decode(input_hex, allocator);
    const path = "data/shakespeare.txt"; // TODO: move to comp time
    const freq = try calc_freq(path);
    var best_score: f32 = std.math.floatMax(f32);
    var best_key: u8 = undefined;
    var best_dec: []u8 = &[_]u8{};
    var key: u8 = 0;
    while (key < 255) {
        const dec = try xor.repeated(key, input_bytes, allocator);
        const score = xor.frequency_analysis(dec, freq);
        if (score < best_score) {
            best_score = score;
            best_key = key;
            best_dec = dec;
        }
        key += 1;
    }

    try std.testing.expect(std.mem.eql(u8, expected_text, best_dec));
    try std.testing.expect(expected_key == best_key);
}

fn calc_freq(filename: [*:0]const u8) ![256]f32 {
    var path_buffer: [std.fs.max_path_bytes]u8 = undefined;
    const path = try std.fs.realpathZ(filename, &path_buffer);
    const file = try std.fs.openFileAbsolute(path, .{});
    var buffered_file = std.io.bufferedReader(file.reader());
    var buffer: [1]u8 = undefined;
    var freqs = std.mem.zeroes([256]f32);
    var read: usize = 1;
    var sum: f32 = 0.0;
    while (read != 0) {
        read = try buffered_file.read(&buffer);
        const c = buffer[0];
        if ((c > 'a' and c < 'z') or (c > 'A' and c < 'Z')) {
            freqs[c] += 1.0;
            sum += 1.0;
        }
    }
    for (&freqs) |*f| {
        f.* /= sum;
    }
    defer file.close();
    return freqs;
}

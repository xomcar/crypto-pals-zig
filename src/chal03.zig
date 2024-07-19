// Single-byte XOR cipher
const std = @import("std");
const xor = @import("lib/xor_cipher.zig");
const hex = @import("lib/hex.zig");
const base64 = @import("lib/base64.zig");

pub fn main() !void {
    const start = std.time.milliTimestamp();
    const expected_text = "Cooking MC's like a pound of bacon";
    const expected_key: u8 = 88;
    const input_hex = "1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    const dec_buffer = try a.alloc(u8, input_hex.len / 2);
    defer a.free(dec_buffer);
    const input_bytes = try hex.decode(input_hex, dec_buffer);
    var best_score: f32 = std.math.floatMax(f32);
    var best_key: u8 = undefined;
    const best_dec_buffer = try a.alloc(u8, input_bytes.len);
    defer a.free(best_dec_buffer);
    var best_dec: []u8 = undefined;
    var key: u8 = 0;
    const temp_buffer = try a.alloc(u8, input_bytes.len);
    defer a.free(temp_buffer);
    while (key < 255) {
        const decoded = try xor.applySingleKey(key, input_bytes, temp_buffer);
        const score = xor.computeFrequencyAnalysis(decoded);
        if (score < best_score) {
            best_score = score;
            best_key = key;
            @memcpy(best_dec_buffer, temp_buffer);
            best_dec = best_dec_buffer[0..decoded.len];
        }
        key += 1;
    }

    try std.testing.expect(std.mem.eql(u8, expected_text, best_dec_buffer));
    try std.testing.expect(expected_key == best_key);

    const end = std.time.milliTimestamp();
    std.debug.print("encrypted input:\n\t{s}\ndecoded to:\n\t{s}\nwith key:\n\t{}\n", .{
        input_bytes,
        best_dec_buffer,
        best_key,
    });
    std.debug.print("took: {} ms", .{end - start});
}

// Single-byte XOR cipher
const std = @import("std");
const xor = @import("lib/xor_cipher.zig");
const hex = @import("lib/hex.zig");
const base64 = @import("lib/base64.zig");

pub fn main() !void {
    const start = std.time.milliTimestamp();
    defer {
        const end = std.time.milliTimestamp();
        std.debug.print("took: {} ms", .{end - start});
    }
    const expected_text = "Cooking MC's like a pound of bacon";
    const expected_key: u8 = 88;
    const input_hex = "1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    const input_bytes = try hex.decode(input_hex, a);
    defer a.free(input_bytes);
    var best_score: f32 = std.math.floatMax(f32);
    var best_key: u8 = undefined;
    var best_dec: ?[]u8 = null;
    defer a.free(best_dec.?);
    var key: u8 = 0;
    while (key < 255) {
        const dec = try xor.applySingleKey(key, input_bytes, a);
        const score = xor.computeFrequencyAnalysis(dec);
        if (score < best_score) {
            if (best_dec != null) {
                a.free(best_dec.?);
            }
            best_score = score;
            best_key = key;
            best_dec = dec;
        } else {
            a.free(dec);
        }
        key += 1;
    }

    try std.testing.expect(std.mem.eql(u8, expected_text, best_dec.?));
    try std.testing.expect(expected_key == best_key);

    std.debug.print("encrypted input:\n\t{s}\ndecoded to:\n\t{s}\nwith key:\n\t{}\n", .{
        input_bytes,
        best_dec.?,
        best_key,
    });
}

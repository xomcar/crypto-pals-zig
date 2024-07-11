const std = @import("std");
const hex = @import("../hex.zig");
const xor = @import("../xor_cipher.zig");
const io = @import("../io.zig");

test "challenge 3" {
    const expected_text = "Cooking MC's like a pound of bacon";
    const expected_key: u8 = 88;
    const input_hex = "1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736";
    const a = std.testing.allocator;
    const input_bytes = try hex.decode(input_hex, a);
    defer a.free(input_bytes);
    const path = "data/shakespeare.txt"; // TODO: move to comp time
    const freq = try io.frequency_table_from(path);
    var best_score: f32 = std.math.floatMax(f32);
    var best_key: u8 = undefined;
    var best_dec: ?[]u8 = null;
    defer a.free(best_dec.?);
    var key: u8 = 0;
    while (key < 255) {
        const dec = try xor.apply_single_key(key, input_bytes, a);
        const score = xor.compute_frequency_analysis(dec, freq);
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
}

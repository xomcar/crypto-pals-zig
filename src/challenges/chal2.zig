const std = @import("std");
const base64 = @import("../base64.zig");
const hex = @import("../hex.zig");
const xor = @import("../xor_cipher.zig");

test "challenge 2" {
    const in1 = "1c0111001f010100061a024b53535009181c";
    const in2 = "686974207468652062756c6c277320657965";
    const expected_output = "746865206b696420646f6e277420706c6179";
    const a = std.testing.allocator;
    const in1_bytes = try hex.decode(in1, a);
    defer a.free(in1_bytes);
    const in2_bytes = try hex.decode(in2, a);
    defer a.free(in2_bytes);
    const xord = try xor.apply_fixed(in1_bytes, in2_bytes, a);
    defer a.free(xord);
    const expected_output_bytes = try hex.decode(expected_output, a);
    defer a.free(expected_output_bytes);
    try std.testing.expect(std.mem.eql(u8, xord, expected_output_bytes));
}

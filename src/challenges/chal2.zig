const std = @import("std");
const base64 = @import("../base64.zig");
const hex = @import("../hex.zig");
const xor = @import("../xor_cipher.zig");

pub fn solve() !void {
    const in1 = "1c0111001f010100061a024b53535009181c";
    const in2 = "686974207468652062756c6c277320657965";
    const expected_output = "746865206b696420646f6e277420706c6179";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const in1_bytes = try hex.decode(in1, allocator);
    const in2_bytes = try hex.decode(in2, allocator);
    const xord = try xor.fixed(in1_bytes, in2_bytes, allocator);
    const expected_output_bytes = try hex.decode(expected_output, allocator);
    try std.testing.expect(std.mem.eql(u8, xord, expected_output_bytes));
}

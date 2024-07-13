const std = @import("std");
const xor = @import("lib/xor_cipher.zig");
const hex = @import("lib/hex.zig");
const base64 = @import("lib/base64.zig");

pub fn main() !void {
    const in1 = "1c0111001f010100061a024b53535009181c";
    const in2 = "686974207468652062756c6c277320657965";
    const expected_output = "746865206b696420646f6e277420706c6179";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    const in1_bytes = try hex.decode(in1, a);
    defer a.free(in1_bytes);
    const in2_bytes = try hex.decode(in2, a);
    defer a.free(in2_bytes);
    const xord = try xor.applyFixed(in1_bytes, in2_bytes, a);
    defer a.free(xord);
    const expected_output_bytes = try hex.decode(expected_output, a);
    defer a.free(expected_output_bytes);
    try std.testing.expect(std.mem.eql(u8, xord, expected_output_bytes));

    std.debug.print("input 1:\n\t{s}\ninput 2:\n\t{s}\nxor: \n{s}\n", .{
        in1_bytes,
        in2_bytes,
        xord,
    });
}

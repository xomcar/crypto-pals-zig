// Fixed XOR
const std = @import("std");
const xor = @import("lib/xor_cipher.zig");
const hex = @import("lib/hex.zig");
const base64 = @import("lib/base64.zig");

pub fn main() !void {
    const start = std.time.milliTimestamp();
    const in1 = "1c0111001f010100061a024b53535009181c";
    const in2 = "686974207468652062756c6c277320657965";
    const expected_output = "746865206b696420646f6e277420706c6179";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    const in1_buffer = try a.alloc(u8, in1.len / 2);
    defer a.free(in1_buffer);

    const in1_bytes = try hex.decode(in1, in1_buffer);

    const in2_buffer = try a.alloc(u8, in2.len / 2);
    defer a.free(in2_buffer);

    const in2_bytes = try hex.decode(in2, in2_buffer);

    std.debug.assert(in1_bytes.len == in2_bytes.len);
    const xor_buffer = try a.alloc(u8, in1_bytes.len);
    defer a.free(xor_buffer);

    const out_bytes = try xor.applyFixed(in1_bytes, in2_bytes, xor_buffer);

    const expected_output_buffer = try a.alloc(u8, expected_output.len / 2);
    defer a.free(expected_output_buffer);

    const expected_output_bytes = try hex.decode(expected_output, expected_output_buffer);
    try std.testing.expect(std.mem.eql(u8, out_bytes, expected_output_bytes));
    const end = std.time.milliTimestamp();

    std.debug.print("input 1:\n\t{s}\ninput 2:\n\t{s}\nxor: \n{s}\n", .{
        in1_bytes,
        in2_bytes,
        out_bytes,
    });
    std.debug.print("took: {} ms", .{end - start});
}

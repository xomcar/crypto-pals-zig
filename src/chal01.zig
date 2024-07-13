const std = @import("std");
const xor = @import("lib/xor_cipher.zig");
const hex = @import("lib/hex.zig");
const base64 = @import("lib/base64.zig");

pub fn main() !void {
    const hex_input = "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d";
    const expected_output = "SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t";

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    const plain_input = try hex.decode(hex_input, a);
    defer a.free(plain_input);
    const output = try base64.encode(plain_input, a);
    defer a.free(output);
    try std.testing.expect(std.mem.eql(u8, expected_output, output));
}

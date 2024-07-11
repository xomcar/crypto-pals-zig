const std = @import("std");
const base64 = @import("../base64.zig");
const hex = @import("../hex.zig");

pub fn solve() !void {
    const hex_input = "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d";
    const expected_output = "SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t";

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const plain_input = try hex.decode(hex_input, allocator);
    const output = try base64.encode(plain_input, allocator);
    try std.testing.expect(std.mem.eql(u8, expected_output, output));
}

const std = @import("std");

const HEX_CHARS = "0123456789abcdef";

fn hexCharToValue(c: u8) !u8 {
    if (c >= '0' and c <= '9') {
        return c - '0';
    } else if (c >= 'a' and c <= 'f') {
        return c - 'a' + 10;
    } else if (c >= 'A' and c <= 'F') {
        return c - 'A' + 10;
    } else {
        return error.InvalidHexCharacter;
    }
}

pub fn decode(hex_string: []const u8, output: []u8) ![]u8 {
    const input_len = hex_string.len;
    std.debug.assert(output.len >= input_len / 2);
    if (input_len % 2 != 0) {
        return error.InvalidHexLength;
    }

    const byte_count = input_len / 2;
    var i: usize = 0;
    while (i < byte_count) : (i += 1) {
        const high_nibble = try hexCharToValue(hex_string[i * 2]);
        const low_nibble = try hexCharToValue(hex_string[i * 2 + 1]);
        output[i] = (high_nibble << 4) | low_nibble;
    }

    return output[0..i];
}

pub fn encode(input_bytes: []const u8, output: []u8) ![]u8 {
    const char_count = input_bytes.len * 2;
    std.debug.assert(output.len >= char_count);
    var i: usize = 0;
    for (input_bytes) |b| {
        const index0 = b >> 4;
        const index1 = (b & 0b0000_1111);
        output[i] = HEX_CHARS[index0];
        output[i + 1] = HEX_CHARS[index1];
        i += 2;
    }
    return output[0..i];
}

test "hex" {
    const test_al = std.testing.allocator;
    const input = "deadbeef";
    const expected_output: [4]u8 = .{ 0xde, 0xad, 0xbe, 0xef };
    const output = try decode(input, test_al);
    const encoded_output = try encode(&expected_output, test_al);
    try std.testing.expect(std.mem.eql(u8, &expected_output, output));
    try std.testing.expect(std.mem.eql(u8, input, encoded_output));
    test_al.free(encoded_output);
    test_al.free(output);
}

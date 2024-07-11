const std = @import("std");
const xor = @import("../xor_cipher.zig");
const hex = @import("../hex.zig");

test "challenge 5" {
    const input =
        \\Burning 'em, if you ain't quick and nimble
        \\I go crazy when I hear a cymbal
    ;
    const expected =
        "0b3637272a2b2e63622c2e69692a23693a2a3c6324202d623d63343c2a26226324272765272a282b2f20430a652e2c652a3124333a653e2b2027630c692b20283165286326302e27282f";
    const a = std.testing.allocator;
    const encrypted = try xor.apply_repeating_key("ICE", input, a);
    defer a.free(encrypted);
    const encoded = try hex.encode(encrypted, a);
    defer a.free(encoded);

    try std.testing.expect(std.mem.eql(u8, encoded, expected));
}

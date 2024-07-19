// Break repeating-key XOR
const std = @import("std");
const xor = @import("lib/xor_cipher.zig");
const hex = @import("lib/hex.zig");
const base64 = @import("lib/base64.zig");
const io = @import("lib/io.zig");
const b = @import("lib/bench.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    const data = try io.readMultilineFile("data/6.txt", a);
    defer a.free(data);
    const start = std.time.milliTimestamp();
    const decoded_data = try base64.decode(data, a);

    defer a.free(decoded_data);
    const key_len = try xor.findEncryptionKeyLength(decoded_data);
    // std.debug.print("candidate best key length:\n\t{}\n", .{key_len});
    const key, const plain_text = try xor.crackXorCipher(key_len, decoded_data, a);
    defer a.free(key);
    defer a.free(plain_text);
    const end = std.time.milliTimestamp();

    std.debug.print("cracked key:\n\t{s}\ndecrypted text:\n{s}\n", .{ key, plain_text });
    std.debug.print("took: {} ms", .{end - start});
}

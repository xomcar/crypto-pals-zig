const std = @import("std");
const xor = @import("lib/xor_cipher.zig");
const hex = @import("lib/hex.zig");
const base64 = @import("lib/base64.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    const data_file = try std.fs.cwd().openFile("data/6.txt", .{});
    var buffer: [1024]u8 = undefined;
    var data_buffer = try a.alloc(u8, (try data_file.stat()).size);
    defer a.free(data_buffer);
    const data_reader = data_file.reader();
    var data_buffer_index: usize = 0;
    while (try data_reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (line[line.len - 1] != '\r') {
            @memcpy(
                data_buffer[data_buffer_index .. data_buffer_index + line.len],
                line,
            );
            data_buffer_index += line.len;
        } else {
            @memcpy(
                data_buffer[data_buffer_index .. data_buffer_index + line.len - 1],
                line[0 .. line.len - 1],
            );
            data_buffer_index += line.len - 1;
        }
    }
    const data = data_buffer[0..data_buffer_index];
    const decoded_data = try base64.decode(data, a);
    defer a.free(decoded_data);
    const key_len = try xor.findEncryptionKeyLength(decoded_data);
    std.debug.print("candidate best key length:\n\t{}\n", .{key_len});

    const key, const plain_text = try xor.crackXorCipher(key_len, decoded_data, a);
    defer a.free(key);
    defer a.free(plain_text);

    std.debug.print("key:\n\t{s}\ntext:\n{s}\n", .{ key, plain_text });
}

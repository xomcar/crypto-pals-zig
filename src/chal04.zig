// Detect single-character XOR
const std = @import("std");
const xor = @import("lib/xor_cipher.zig");
const hex = @import("lib/hex.zig");
const base64 = @import("lib/base64.zig");

pub fn main() !void {
    const data_file = try std.fs.cwd().openFile("data/4.txt", .{});
    const data_reader = data_file.reader();
    var buf: [1024]u8 = undefined;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();

    const expected_text = "Now that the party is jumping\n";
    var min_dist = std.math.floatMax(f32);
    var best_output: []u8 = undefined;
    var best_input: []u8 = undefined;
    var best_key: u8 = undefined;
    var candidate_text_input_buffer: [1024]u8 = undefined;
    var candidate_text_output_buffer: [1024]u8 = undefined;

    while (try data_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const hex_dec_buffer = try a.alloc(u8, line.len / 2);
        defer a.free(hex_dec_buffer);
        const enc_text = try hex.decode(line, hex_dec_buffer);

        var key: u8 = 0;
        const dec_text_buffer = try a.alloc(u8, enc_text.len);
        defer a.free(dec_text_buffer);
        while (key < 255) : (key += 1) {
            const dec_text = try xor.applySingleKey(key, enc_text, dec_text_buffer);
            const dist = xor.computeFrequencyAnalysis(dec_text);
            if (dist < min_dist) {
                min_dist = dist;
                best_key = key;
                @memcpy(candidate_text_input_buffer[0..enc_text.len], enc_text);
                @memcpy(candidate_text_output_buffer[0..dec_text.len], dec_text);
                best_input = candidate_text_input_buffer[0..enc_text.len];
                best_output = candidate_text_output_buffer[0..dec_text.len];
            }
        }
    }
    try std.testing.expect(std.mem.eql(u8, expected_text, best_output));

    std.debug.print("encryped input:\n\t{s}\ndecryped output:\n\t{s}\nwith key:\n\t{}\n", .{
        best_input,
        best_output,
        best_key,
    });
}

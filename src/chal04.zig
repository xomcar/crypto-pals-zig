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
    var best_line: ?[]u8 = null;
    var best_key: u8 = undefined;
    var candidate_text: [1024]u8 = undefined;
    defer a.free(best_line.?);

    while (try data_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var trimmed_line = line;
        if (line[line.len - 1] == '\r') {
            trimmed_line = line[0 .. line.len - 1];
        }
        const enc_text = try hex.decode(trimmed_line, a);
        defer a.free(enc_text);
        var key: u8 = 0;
        while (key < 255) : (key += 1) {
            const dec_text = try xor.applySingleKey(key, enc_text, a);
            const dist = xor.computeFrequencyAnalysis(dec_text);
            if (dist < min_dist) {
                min_dist = dist;
                if (best_line != null) {
                    a.free(best_line.?);
                }
                best_line = dec_text;
                best_key = key;
                @memcpy(candidate_text[0..enc_text.len], enc_text);
            } else {
                a.free(dec_text);
            }
        }
    }
    try std.testing.expect(std.mem.eql(u8, expected_text, best_line.?));

    std.debug.print("encryped input:\n\t{s}\ndecryped output:\n\t{s}\nwith key:\n\t{}\n", .{
        candidate_text,
        best_line.?,
        best_key,
    });
}

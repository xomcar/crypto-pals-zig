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
    // defer a.free(best_line.?);

    while (try data_reader.readUntilDelimiterOrEof(&buf, '\r')) |line| {
        std.debug.print("{} {s}\n", .{ line.len, line });
        const enc_text = try hex.decode(line, a);
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
            } else {
                a.free(dec_text);
            }
        }
    }
    try std.testing.expect(std.mem.eql(u8, expected_text, best_line.?));
}

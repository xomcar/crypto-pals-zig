const std = @import("std");
const xor = @import("../xor_cipher.zig");
const io = @import("../io.zig");
const hex = @import("../hex.zig");

pub fn solve() !void {
    const data_file = try std.fs.cwd().openFile("data/4.txt", .{});
    const data_reader = data_file.reader();
    const freq = try io.frequency_table_from("data/shakespeare.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    var buf: [1024]u8 = undefined;

    const expected_text = "Now that the party is jumping\n";
    var min_dist = std.math.floatMax(f32);
    var best_line: ?[]u8 = null;
    while (try data_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const enc_text = try hex.decode(line, a);
        defer a.free(enc_text);
        var key: u8 = 0;
        while (key < 255) : (key += 1) {
            const dec_text = try xor.apply_single_key(key, enc_text, a);
            const dist = xor.compute_frequency_analysis(dec_text, freq);
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

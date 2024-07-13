const std = @import("std");
const hex = @import("hex.zig");

const PADDING: u8 = '=';
const BASE64_ENCODE_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
const BASE64_DECODE_ALPHABET = createDecodeTable();

pub fn createDecodeTable() [256]u8 {
    var decode_table: [256]u8 = [_]u8{255} ** 256;
    var i: usize = 0;
    while (i < BASE64_ENCODE_ALPHABET.len) : (i += 1) {
        decode_table[BASE64_ENCODE_ALPHABET[i]] = @intCast(i);
    }
    return decode_table;
}

pub fn encode(input: []const u8, a: std.mem.Allocator) ![]u8 {
    const enc_size: usize = @intFromFloat(4 * @ceil((@as(f32, @floatFromInt(input.len)) / 3.0)));
    const enc = try a.alloc(u8, enc_size);
    var i: usize = 0;
    while (i < input.len) : (i += 3) {
        const enc_i = 4 * i / 3;
        const b0 = input[i];
        const b1 = if (i + 1 < input.len) input[i + 1] else 0;
        const b2 = if (i + 2 < input.len) input[i + 2] else 0;

        const index0 = b0 >> 2;
        const index1 = (b0 & 0b0000_0011) << 4 | (b1 >> 4);
        const index2 = (b1 & 0b0000_1111) << 2 | (b2 >> 6);
        const index3 = (b2 & 0b0011_1111);

        enc[enc_i] = BASE64_ENCODE_ALPHABET[index0];
        enc[enc_i + 1] = BASE64_ENCODE_ALPHABET[index1];

        if (i + 1 < input.len) {
            enc[enc_i + 2] = BASE64_ENCODE_ALPHABET[index2];
        } else {
            enc[enc_i + 2] = PADDING;
            enc[enc_i + 3] = PADDING;
            break;
        }

        if (i + 2 < input.len) {
            enc[enc_i + 3] = BASE64_ENCODE_ALPHABET[index3];
        } else {
            enc[enc_i + 3] = PADDING;
            break;
        }
    }
    return enc;
}

pub fn decode(input: []const u8, a: std.mem.Allocator) ![]u8 {
    const len = input.len;
    var buf: [4]u8 = undefined;
    var buf_i: usize = 0;
    if (len % 4 != 0) {
        return error.InvalidBase64Length;
    }
    var dec_size: usize = (input.len / 4) * 3;
    if (input[input.len - 2] == PADDING) {
        dec_size -= 2;
    } else if (input[input.len - 1] == PADDING) {
        dec_size -= 1;
    }
    const dec = try a.alloc(u8, dec_size);
    var dec_i: usize = 0;
    for (input) |c| {
        if (c == PADDING) {
            break;
        }
        const dec_val = BASE64_DECODE_ALPHABET[c];
        if (dec_val == 255) {
            return error.InvalidBase64String;
        }
        buf[buf_i] = dec_val;
        buf_i += 1;

        if (buf_i == 4) {
            const first = (buf[0] << 2) | buf[1] >> 4;
            const second = ((buf[1] & 0b0000_1111) << 4 | (buf[2] >> 2));
            const third = (buf[2] & 0b0000_0011) << 6 | buf[3];
            dec[dec_i] = first;
            dec[dec_i + 1] = second;
            dec[dec_i + 2] = third;
            dec_i += 3;
            buf_i = 0;
        }
    }

    if (buf_i == 3) {
        const first = (buf[0] << 2) | buf[1] >> 4;
        const second = ((buf[1] & 0b0000_1111) << 4 | (buf[2] >> 2));
        dec[dec_i] = first;
        dec_i += 1;
        if (buf[2] != PADDING) {
            dec[dec_i] = second;
            dec_i += 1;
        }
    } else if (buf_i == 2) {
        const first = (buf[0] << 2) | buf[1] >> 4;
        dec[dec_i] = first;
    }

    return dec;
}

test "base64" {
    const test_al = std.testing.allocator;
    const inputs: []const []const u8 = &.{
        "amabaadnaiodnwoaidnaoiwndoiwadna",
        "9100192kd109d1m09d221md0",
        "-01d0am29mdc0k-0ck1ck10ck10ck1c010c1c01c1-1l1-laa",
        "I'm killing your brain like a poisonous mushroom",
    };
    const outputs: []const []const u8 = &.{
        "YW1hYmFhZG5haW9kbndvYWlkbmFvaXduZG9pd2FkbmE=",
        "OTEwMDE5MmtkMTA5ZDFtMDlkMjIxbWQw",
        "LTAxZDBhbTI5bWRjMGstMGNrMWNrMTBjazEwY2sxYzAxMGMxYzAxYzEtMWwxLWxhYQ==",
        "SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t",
    };
    for (inputs, outputs) |in, out| {
        const encoded_input = try encode(in, test_al);
        const decoded_output = try decode(out, test_al);
        defer test_al.free(encoded_input);
        defer test_al.free(decoded_output);
        //std.debug.print("{s}\n{s}\n{s}\n{s}\n", .{ in, decoded_output, out, encoded_input });
        try std.testing.expect(std.mem.eql(u8, in, decoded_output));
        try std.testing.expect(std.mem.eql(u8, out, encoded_input));
    }
}

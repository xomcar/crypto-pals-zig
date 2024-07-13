const std = @import("std");
const english_freqs = @import("frequency.zig").freq;

pub fn applyFixed(in1: []const u8, in2: []const u8, a: std.mem.Allocator) ![]u8 {
    if (in1.len != in2.len) return error.InputLengthMismatch;
    var output = try a.alloc(u8, in1.len);
    var i: usize = 0;
    for (in1, in2) |e1, e2| {
        output[i] = e1 ^ e2;
        i += 1;
    }
    return output;
}

pub fn applySingleKey(key: u8, input: []const u8, a: std.mem.Allocator) ![]u8 {
    var output = try a.alloc(u8, input.len);
    var i: usize = 0;
    for (input) |b| {
        output[i] = b ^ key;
        i += 1;
    }
    return output;
}

pub fn applyRepeatingKey(key: []const u8, input: []const u8, a: std.mem.Allocator) ![]u8 {
    var output = try a.alloc(u8, input.len);
    var i: usize = 0;
    for (input) |b| {
        output[i] = b ^ key[i % key.len];
        i += 1;
    }
    return output;
}

fn hammingWeight(b: u8) usize {
    var bits_set: usize = 0;
    var datum = b;
    while (datum != 0) : (datum >>= 1) {
        bits_set +%= datum & 1;
    }
    return bits_set;
}

pub fn hammingDistance(in1: []const u8, in2: []const u8) !usize {
    if (in1.len != in2.len) {
        return error.InputLengthMismatch;
    }
    var distance: usize = 0;
    for (in1, in2) |a, b| {
        const res = a ^ b;
        distance += hammingWeight(res);
    }
    return distance;
}

test "hamming distance" {
    try std.testing.expect(37 == try hammingDistance("this is a test", "wokka wokka!!!"));
}

pub fn computeFrequencyAnalysis(text: []const u8) f32 {
    var actual_freqs = std.mem.zeroes([256]f32);
    for (text) |c| {
        actual_freqs[c] += 1.0;
    }
    var dist: f32 = 0.0;
    for (actual_freqs, english_freqs) |count, exp_f| {
        const diff = (count - exp_f * @as(f32, @floatFromInt(text.len)));
        dist += diff * diff / actual_freqs.len;
    }
    return dist;
}

pub fn findEncryptionKeyLength(encrypted_text: []const u8) !usize {
    var best_dist: f32 = std.math.floatMax(f32);
    var best_key_len: usize = 0;
    for (2..40) |key_len| {
        var dist: f32 = 0;
        var words: [4][]const u8 = undefined;
        var permutations: f32 = 0;
        words[0] = encrypted_text[0..][0..key_len];
        words[1] = encrypted_text[key_len..][0..key_len];
        words[2] = encrypted_text[2 * key_len ..][0..key_len];
        words[3] = encrypted_text[3 * key_len ..][0..key_len];
        for (words) |w1| {
            for (words) |w2| {
                if (std.mem.eql(u8, w1, w2)) continue;
                dist += @as(f32, @floatFromInt(try hammingDistance(w1, w2)));
                permutations += 1;
            }
        }
        const norm_dist: f32 = dist / permutations / @as(f32, @floatFromInt(key_len));
        if (norm_dist < best_dist) {
            best_key_len = key_len;
            best_dist = norm_dist;
        }
    }
    return best_key_len;
}

pub fn crackXorCipher(key_len: usize, encrypted_text: []const u8, a: std.mem.Allocator) !struct { []u8, []u8 } {
    var encrypted_word = try a.alloc(u8, key_len);
    defer a.free(encrypted_word);
    var secret = try a.alloc(u8, key_len);

    for (0..key_len) |nth_key| {
        for (0..key_len) |i| {
            encrypted_word[i] = encrypted_text[nth_key + i * key_len];
        }
        var best_candidate: u8 = 0;
        var min_dist = std.math.floatMax(f32);
        var candidate: u8 = 0;
        while (candidate < 255) : (candidate += 1) {
            const dec = try applySingleKey(candidate, encrypted_word, a);
            defer a.free(dec);
            const d = computeFrequencyAnalysis(dec);
            if (d < min_dist) {
                min_dist = d;
                best_candidate = candidate;
            }
        }
        secret[nth_key] = best_candidate;
    }
    const decrypted_data = try applyRepeatingKey(secret, encrypted_text, a);
    return .{ secret, decrypted_data };
}

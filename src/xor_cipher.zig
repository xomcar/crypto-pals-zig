const std = @import("std");

const english_frequency = std.mem.zeroes([256]f32);

pub fn apply_fixed(in1: []const u8, in2: []const u8, a: std.mem.Allocator) ![]u8 {
    if (in1.len != in2.len) return error.InputLengthMismatch;
    var output = try a.alloc(u8, in1.len);
    var i: usize = 0;
    for (in1, in2) |e1, e2| {
        output[i] = e1 ^ e2;
        i += 1;
    }
    return output;
}

pub fn apply_single_key(key: u8, input: []const u8, a: std.mem.Allocator) ![]u8 {
    var output = try a.alloc(u8, input.len);
    var i: usize = 0;
    for (input) |b| {
        output[i] = b ^ key;
        i += 1;
    }
    return output;
}

pub fn apply_repeating_key(key: []const u8, input: []const u8, a: std.mem.Allocator) ![]u8 {
    var output = try a.alloc(u8, input.len);
    var i: usize = 0;
    for (input) |b| {
        output[i] = b ^ key[i % key.len];
        i += 1;
    }
    return output;
}

fn hamming_weight(b: u8) usize {
    var bits_set: usize = 0;
    var datum = b;
    while (datum != 0) : (datum >>= 1) {
        bits_set +%= datum & 1;
    }
    return bits_set;
}

pub fn hamming_distance(in1: []const u8, in2: []const u8) !usize {
    if (in1.len != in2.len) {
        return error.InputLengthMismatch;
    }
    var distance: usize = 0;
    for (in1, in2) |a, b| {
        const res = a ^ b;
        distance += hamming_weight(res);
    }
    return distance;
}

pub fn compute_frequency_analysis(text: []const u8, fs: [256]f32) f32 {
    var freq = std.mem.zeroes([256]f32);
    for (text) |c| {
        freq[c] += 1.0;
    }
    var dist: f32 = 0.0;
    for (freq, fs) |f1, f2| {
        dist += @abs(f1 / freq.len - f2);
    }
    return dist;
}

test "hamming distance" {
    try std.testing.expect(37 == try hamming_distance("this is a test", "wokka wokka!!!"));
}

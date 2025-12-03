const std = @import("std");
const aoc = @import("aoc");

pub fn run(_: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var score1: u64 = 0;
    var score2: u64 = 0;
    while (try lines.next()) |line| {
        if (line.len < 12) return error.LineTooShort;

        const i = std.mem.indexOfMax(u8, line[0 .. line.len - 1]);

        const j = std.mem.indexOfMax(u8, line[i + 1 ..]) + i + 1;

        score1 += (line[i] - '0') * 10 + (line[j] - '0');

        var start: usize = 0;
        for (0..12) |k| {
            const idx = std.mem.indexOfMax(u8, line[start .. line.len - 11 + k]) + start;
            start = idx + 1; // for the digit start to the right of this one

            score2 += try std.math.powi(u64, 10, 11 - k) * (line[idx] - '0');
        }
    }

    return .{ score1, score2 };
}

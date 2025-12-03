// Advent of code 25 - day 1
const std = @import("std");
const aoc = @import("aoc");

pub fn run(_: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var pos: i16 = 50;
    var score1: u32 = 0;
    var score2: u32 = 0;
    while (try lines.next()) |line| {
        if (line.len == 0) continue; // skip empty lines
        const sign: i16 =
            switch (line[0]) {
                'R' => 1,
                'L' => -1,
                else => return error.InvalidDirection,
            };
        const d = try std.fmt.parseInt(i16, line[1..], 10);

        const new_pos = @mod(pos + sign * d, 100);

        if (new_pos == 0) score1 += 1;

        if (sign > 0) score2 += @abs(@divFloor(pos + d, 100)) // fwd

        else score2 += @abs(@divFloor(@mod(100 - pos, 100) + d, 100)); // bwd

        pos = @intCast(new_pos);
    }

    return .{ score1, score2 };
}

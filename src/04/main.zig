// Advent of code 25 - day 4
const std = @import("std");
const aoc = @import("aoc");

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    var g = try lines.readGrid(a);
    var g2 = try aoc.Grid.initWith(a, g.n, g.m, 0);

    var score1: usize = 0;
    var score2: usize = 0;
    while (true) {
        var cnt: usize = 0;
        for (0..g.n) |i| {
            for (0..g.m) |j| {
                g2.set(i, j, g.at(i, j));
                if (g.at(i, j) != '@') continue;
                var c: usize = 0;
                for (@max(1, i) - 1..@min(g.n - 2, i) + 2) |y| {
                    for (@max(1, j) - 1..@min(g.m - 2, j) + 2) |x| {
                        if ((y != i or x != j) and g.at(y, x) == '@') c += 1;
                    }
                }
                if (c < 4) {
                    cnt += 1;
                    g2.set(i, j, '.');
                }
            }
        }
        if (cnt == 0) break;
        if (score1 == 0) score1 = cnt;
        score2 += cnt;
        std.mem.swap(aoc.Grid, &g, &g2);
    }

    return .{ score1, score2 };
}

pub fn main() !void {
    var buffer: [2]u8 = undefined;
    const name = try std.fmt.bufPrint(&buffer, "{:02}", .{4});
    return aoc.run(name, run);
}

test "Day 4 part 1" {
    try aoc.run_tests(run, 4, 1);
}

test "Day 4 part 2" {
    try aoc.run_tests(run, 4, 2);
}

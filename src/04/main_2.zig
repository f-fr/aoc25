// Advent of code 25 - day 4
const std = @import("std");
const aoc = @import("aoc");

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    var g = try lines.readGridWithBoundary(a, '.');
    var degrees = try aoc.Grid.initWith(a, g.n, g.m, 42);

    for (1..g.n - 1) |i| {
        for (1..g.m - 1) |j| {
            if (g.at(i, j) != '@') {
                degrees.set(i, j, 42);
            } else {
                var d: u8 = 0;
                for (i - 1..i + 2) |y| {
                    for (j - 1..j + 2) |x| {
                        if (g.at(y, x) == '@') d += 1;
                    }
                }
                std.debug.assert(d > 0);
                degrees.set(i, j, d);
            }
        }
    }

    var removable: std.ArrayList(aoc.Pos) = .empty;
    for (0..g.n) |i| {
        for (0..g.m) |j| {
            if (degrees.at(i, j) <= 4) {
                try removable.append(a, .{ .i = i, .j = j });
            }
        }
    }

    const score1 = removable.items.len;
    var score2: usize = 0;
    while (removable.pop()) |pos| {
        score2 += 1;
        const i = pos.i;
        const j = pos.j;
        for (i - 1..i + 2) |y| {
            for (j - 1..j + 2) |x| {
                const deg = degrees.at(y, x);
                if (deg >= 5) {
                    degrees.set(y, x, deg - 1);
                    if (deg == 5) try removable.append(a, .{ .i = y, .j = x });
                }
            }
        }
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

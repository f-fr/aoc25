const std = @import("std");
const aoc = @import("aoc");

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    // read grid with boundary of empty squares
    var g = try lines.readGridWithBoundary(a, '.');

    var degrees = try aoc.Grid.initWith(a, g.n, g.m, 42);
    var removable: std.ArrayList(aoc.Pos) = .empty;
    for (1..g.n - 1) |i| {
        for (1..g.m - 1) |j| {
            if (g.at(i, j) == '@') {
                var d: u8 = 0;
                for (i - 1..i + 2) |y| {
                    for (j - 1..j + 2) |x| {
                        if (g.at(y, x) == '@') d += 1;
                    }
                }
                degrees.set(i, j, d);
                // d - 1 because we count the square itself
                if (d - 1 < 4) try removable.append(a, .{ .i = i, .j = j });
            }
        }
    }

    const score1 = removable.items.len;

    var score2: usize = 0;
    while (removable.pop()) |pos| {
        score2 += 1; // the score is the number of all removed squares
        const i = pos.i;
        const j = pos.j;
        for (i - 1..i + 2) |y| {
            for (j - 1..j + 2) |x| {
                const deg = degrees.at(y, x);
                if (deg - 1 == 4) {
                    // degree drops below 4, so remove this
                    // neighbor as well
                    try removable.append(a, .{ .i = y, .j = x });
                    // mark this square as empty
                }
                degrees.set(y, x, deg - 1);
            }
        }
    }

    return .{ score1, score2 };
}

// Advent of code 25 - day 7
const std = @import("std");
const aoc = @import("aoc");

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    var g = try lines.readGridWithBoundary(a, '.');
    var cnt = try aoc.GridT(u64).initWith(a, g.n, g.m, 0);

    var q: std.Deque(aoc.Pos) = .empty;
    try q.ensureTotalCapacity(a, g.m);

    const s = g.findFirst('S') orelse return error.MissingStart;
    q.pushBackAssumeCapacity(s);
    cnt.setPos(s, 1);

    var score1: u32 = 0;
    while (q.popFront()) |p| {
        if (p.i + 1 == g.n) continue; // reach the bottom of the grid
        if (g.at(p.i + 1, p.j) == '^') score1 += 1;
        const nexts = if (g.at(p.i + 1, p.j) == '^') &[_]usize{ p.j - 1, p.j + 1 } else &[_]usize{p.j};
        for (nexts) |j| {
            const n = aoc.Pos{ .i = p.i + 1, .j = j };
            cnt.refPos(n).* += cnt.atPos(p);
            if (g.atPos(n) == '.') {
                g.setPos(n, '|');
                q.pushBackAssumeCapacity(n);
            }
        }
    }

    var score2: u64 = 0;
    for (0..g.m) |j| score2 += cnt.at(g.n - 1, j);

    return .{ score1, score2 };
}

pub fn main() !void {
    var buffer: [2]u8 = undefined;
    const name = try std.fmt.bufPrint(&buffer, "{:02}", .{7});
    return aoc.run(name, run);
}

test "Day 7 part 1" {
    try aoc.run_tests(run, 7, 1);
}

test "Day 7 part 2" {
    try aoc.run_tests(run, 7, 2);
}

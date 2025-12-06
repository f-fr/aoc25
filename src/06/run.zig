const std = @import("std");
const aoc = @import("aoc");

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    var g = try lines.readGridFilled(a, ' ');

    var ops = try aoc.splitA(a, g.row(g.n - 1), " ");
    // ignore last row
    g.n -= 1;

    var nums = try aoc.toNumsA(u64, a, g.row(0), " ");

    for (1..g.n) |i| {
        var toks = std.mem.tokenizeSequence(u8, g.row(i), " ");

        var j: usize = 0;
        while (toks.next()) |tok| {
            if (ops[j][0] == '+')
                nums[j] += try aoc.toNum(u32, tok)
            else
                nums[j] *= try aoc.toNum(u32, tok);
            j += 1;
        }
    }

    var score1: u64 = 0;
    for (nums) |n| score1 += n;

    var g2 = try g.rotateLeft(a);

    var i: usize = 0;
    var j: usize = 0;

    var score2: u64 = 0;
    while (j < ops.len) : (j += 1) {

        if (ops[ops.len - j - 1][0] == '+') {
            var s: u64 = 0;
            while (i < g2.n) : (i += 1) {
                s += aoc.toNum(u32, g2.row(i)) catch break;
            }
            score2 += s;

        } else {
            var p: u64 = 1;
            while (i < g2.n) : (i += 1) {
                p *= aoc.toNum(u32, g2.row(i)) catch break;
            }
            score2 += p;
        }

        // skip empty lines
        while (i < g2.n and std.mem.trim(u8, g2.row(i), " ").len == 0) i += 1;
    }

    return .{ score1, score2 };
}

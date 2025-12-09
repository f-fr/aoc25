// Advent of code 25 - day 9
const std = @import("std");
const aoc = @import("aoc");

const Pnt = @Vector(2, f64);
const Segment = [2]Pnt;

fn intersects(seg1: Segment, seg2: Segment) bool {
    const a = seg1[0] - seg1[1];
    const b = seg2[1] - seg2[0];
    const c = seg2[1] - seg1[1];
    const det = a[0] * b[1] - a[1] * b[0];
    if (det == 0) return false;
    const alpha = (b[1] * c[0] - b[0] * c[1]) / det;
    const beta = (-a[1] * c[0] + a[0] * c[1]) / det;
    return 1e-6 < alpha and alpha < 1 - 1e-6 and 1e-6 < beta and beta < 1 - 1e-6;
}

fn makeRect(p: Pnt, q: Pnt) [4]Pnt {
    var tl = @min(p, q);
    var br = @max(p, q);
    var tr = Pnt{ br[0], tl[1] };
    var bl = Pnt{ tl[0], br[1] };
    if (tl[0] != br[0]) {
        // different x
        tl[0] += 0.25;
        bl[0] += 0.25;
        tr[0] -= 0.25;
        br[0] -= 0.25;
    }
    if (tl[1] != br[1]) {
        // different y
        tl[1] += 0.25;
        bl[1] -= 0.25;
        tr[1] += 0.25;
        br[1] -= 0.25;
    }
    return .{ tl, tr, br, bl };
}

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    var pnts: std.ArrayList(Pnt) = .empty;
    while (try lines.next()) |line| {
        try pnts.append(a, try aoc.toNums(f64, 2, line, ","));
    }
    const n = pnts.items.len;

    var score1: u64 = 0;
    var score2: u64 = 0;
    for (pnts.items, 0..) |p, i| {
        for (pnts.items[i + 1 ..]) |q| {
            const area: u64 = @intFromFloat(@reduce(.Mul, @abs(p - q) + @as(@Vector(2, f64), @splat(1))));
            score1 = @max(score1, area);

            if (area < score2) continue;

            const m = (p + q) / @as(Pnt, @splat(2)) + Pnt{ 0.25, 0.25 };
            const left = Pnt{ 0, m[1] };
            var cnt: usize = 0;
            for (0..n) |j| {
                const k = (j + 1) % n;
                if (intersects(.{ pnts.items[j], pnts.items[k] }, .{ left, m })) cnt += 1;
            }
            if (cnt % 2 == 0) continue;
            const rect = makeRect(p, q);

            for (0..n) |j| {
                const k = (j + 1) % n;
                const l = .{ pnts.items[j], pnts.items[k] };
                if (intersects(l, .{ rect[0], rect[1] })) break;
                if (intersects(l, .{ rect[1], rect[2] })) break;
                if (intersects(l, .{ rect[2], rect[3] })) break;
                if (intersects(l, .{ rect[3], rect[0] })) break;
            } else {
                score2 = @max(score2, area);
            }
        }
    }

    return .{ score1, score2 };
}

pub fn main() !void {
    var buffer: [2]u8 = undefined;
    const name = try std.fmt.bufPrint(&buffer, "{:02}", .{9});
    return aoc.run(name, run);
}

test "Day 9 part 1" {
    try aoc.run_tests(run, 9, 1);
}

test "Day 9 part 2" {
    try aoc.run_tests(run, 9, 2);
}

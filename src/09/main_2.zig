// Advent of code 25 - day 9
const std = @import("std");
const aoc = @import("aoc");

const Pnt = @Vector(2, i32);
const Segment = [2]Pnt;

fn makeRect(p: Pnt, q: Pnt) struct { top: i32, left: i32, right: i32, bottom: i32 } {
    var tl = @min(p, q);
    var br = @max(p, q);
    inline for (0..2) |i| {
        if (tl[i] != br[i]) {
            tl[i] += 1;
            br[i] -= 1;
        }
    }
    return .{ .top = tl[1], .bottom = br[1], .left = tl[0], .right = br[0] };
}

fn lessByX(pnts: []const Pnt, i: usize, j: usize) bool {
    return pnts[i][0] < pnts[j][0];
}

fn lessByY(pnts: []const Pnt, i: usize, j: usize) bool {
    return pnts[i][1] < pnts[j][1];
}

fn cmpByX(ctx: struct { []const Pnt, i32 }, i: usize) std.math.Order {
    const pnts, const x = ctx;
    return std.math.order(x, pnts[i][0]);
}

fn cmpByY(ctx: struct { []const Pnt, i32 }, i: usize) std.math.Order {
    const pnts, const y = ctx;
    return std.math.order(y, pnts[i][1]);
}

fn intersectsHoriz(pnts: []const Pnt, by_x: []const usize, x1: i32, x2: i32, y: i32) bool {
    const i_start = std.sort.lowerBound(usize, by_x, .{ pnts, x1 }, cmpByX);
    const n = pnts.len;
    for (by_x[i_start..]) |i| {
        if (pnts[i][0] > x2) break;
        const j = (i + 1) % n;
        const y1 = @min(pnts[i][1], pnts[j][1]);
        const y2 = @max(pnts[i][1], pnts[j][1]);
        if (y1 <= y and y <= y2) return true;
    }
    return false;
}

fn countHorizIntersections(pnts: []const Pnt, by_x: []const usize, x1: i32, x2: i32, y: i32) usize {
    const i_start = std.sort.lowerBound(usize, by_x, .{ pnts, x1 }, cmpByX);
    const n = pnts.len;
    var cnt: usize = 0;
    for (by_x[i_start..]) |i| {
        if (pnts[i][0] > x2) break;
        const j = (i + 1) % n;
        const y1 = @min(pnts[i][1], pnts[j][1]);
        const y2 = @max(pnts[i][1], pnts[j][1]);
        if (y1 <= y and y <= y2) cnt += 1;
    }
    return cnt;
}

fn intersectsVert(pnts: []const Pnt, by_y: []const usize, y1: i32, y2: i32, x: i32) bool {
    const i_start = std.sort.lowerBound(usize, by_y, .{ pnts, y1 }, cmpByY);
    const n = pnts.len;
    for (by_y[i_start..]) |i| {
        if (pnts[i][1] > y2) break;
        const j = (i + 1) % n;
        if (pnts[i][1] != pnts[j][1]) continue; // only horizontal
        const x1 = @min(pnts[i][0], pnts[j][0]);
        const x2 = @max(pnts[i][0], pnts[j][0]);
        if (x1 <= x and x <= x2) return true;
    }
    return false;
}

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    var pnts: std.ArrayList(Pnt) = .empty;
    while (try lines.next()) |line| {
        try pnts.append(a, try aoc.toNums(i32, 2, line, ","));
        pnts.items[pnts.items.len - 1][0] *= 2;
        pnts.items[pnts.items.len - 1][1] *= 2;
    }
    const n = pnts.items.len;

    var by_x: std.ArrayList(usize) = .empty;
    var by_y: std.ArrayList(usize) = .empty;
    for (0..n) |i| {
        const j = (i + 1) % n;
        if (pnts.items[i][0] == pnts.items[j][0]) try by_x.append(a, i) else //if (pnts.items[i][1] == pnts.items[j][1])
        try by_y.append(a, i);
    }
    std.mem.sortUnstable(usize, by_x.items, pnts.items, lessByX);
    std.mem.sortUnstable(usize, by_y.items, pnts.items, lessByY);

    var score1: u64 = 0;
    var score2: u64 = 0;
    for (pnts.items, 0..) |p, i| {
        for (pnts.items[i + 1 ..]) |q| {
            const area: u64 = @reduce(.Mul, @abs(p - q) + @as(@Vector(2, u64), @splat(2))) / 4;
            score1 = @max(score1, area);

            if (area < score2) continue;

            const m = (p + q) / @as(Pnt, @splat(2)) + Pnt{ 1, 1 };
            const cnt = countHorizIntersections(pnts.items, by_x.items, 0, m[0], m[1]);
            if (cnt % 2 == 0) continue;
            const rect = makeRect(p, q);

            if (intersectsHoriz(pnts.items, by_x.items, rect.left, rect.right, rect.top)) continue;
            if (intersectsHoriz(pnts.items, by_x.items, rect.left, rect.right, rect.bottom)) continue;
            if (intersectsVert(pnts.items, by_y.items, rect.top, rect.bottom, rect.left)) continue;
            if (intersectsVert(pnts.items, by_y.items, rect.top, rect.bottom, rect.right)) continue;

            score2 = @max(score2, area);
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

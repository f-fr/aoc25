// Advent of code 25 - day 9
const std = @import("std");
const aoc = @import("aoc");

const Pnt = @Vector(2, i32);

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

fn cmpI32(u: i32, v: i32) std.math.Order {
    return std.math.order(u, v);
}

fn unique(comptime T: type, items: []T) []T {
    var skip: usize = 0;
    for (1..items.len) |i| {
        if (items[i] == items[i - 1])
            skip += 1
        else
            items[i - skip] = items[i];
    }
    return items[0 .. items.len - skip];
}

fn countIntersects(xs: []const i32, x_pnts: []const std.ArrayList(i32), x: i32, y1: i32, y2: i32) usize {
    const i = std.sort.binarySearch(i32, xs, x, cmpI32).?;
    const j1 = std.sort.lowerBound(i32, x_pnts[i].items, y1, cmpI32);
    const j2 = std.sort.upperBound(i32, x_pnts[i].items[j1..], y2, cmpI32);
    return j2;
}

fn intersects(xs: []const i32, x_pnts: []const std.ArrayList(i32), x: i32, y1: i32, y2: i32) bool {
    return countIntersects(xs, x_pnts, x, y1, y2) > 0;
}

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    var pnts: std.ArrayList(Pnt) = .empty;
    while (try lines.next()) |line| {
        try pnts.append(a, try aoc.toNums(i32, 2, line, ",") * @as(Pnt, @splat(2)));
    }
    const n = pnts.items.len;

    var xs_all = try a.alloc(i32, 2 * n);
    var ys_all = try a.alloc(i32, 2 * n);
    for (pnts.items, 0..) |p, i| {
        xs_all[2 * i] = p[0] - 1;
        xs_all[2 * i + 1] = p[0] + 1;
        ys_all[2 * i] = p[1] - 1;
        ys_all[2 * i + 1] = p[1] + 1;
    }
    aoc.sort(i32, xs_all);
    aoc.sort(i32, ys_all);
    const xs = unique(i32, xs_all);
    const ys = unique(i32, ys_all);

    const x_pnts = try a.alloc(std.ArrayList(i32), xs.len);
    @memset(x_pnts, .empty);
    const y_pnts = try a.alloc(std.ArrayList(i32), ys.len);
    @memset(y_pnts, .empty);

    // compute intersections for each x and y
    for (0..n) |i| {
        const p = pnts.items[i];
        const q = pnts.items[(i + 1) % n];
        if (p[0] == q[0]) {
            // same x → vertical line
            const j1 = std.sort.lowerBound(i32, ys, @min(p[1], q[1]), cmpI32);
            const j2 = std.sort.lowerBound(i32, ys, @max(p[1], q[1]), cmpI32);
            for (y_pnts[j1..j2]) |*y| try y.append(a, p[0]);
        } else {
            // same y → horizontal line
            const j1 = std.sort.lowerBound(i32, xs, @min(p[0], q[0]), cmpI32);
            const j2 = std.sort.lowerBound(i32, xs, @max(p[0], q[0]), cmpI32);
            for (x_pnts[j1..j2]) |*x| try x.append(a, p[1]);
        }
    }

    for (x_pnts) |x| aoc.sort(i32, x.items);
    for (y_pnts) |y| aoc.sort(i32, y.items);

    var score1: u64 = 0;
    var score2: u64 = 0;
    for (pnts.items, 0..) |p, i| {
        var last_failed = false;
        var last_area: u64 = 0;
        for (pnts.items[i + 1 ..]) |q| {
            const area: u64 = @reduce(.Mul, @abs(p - q) + @as(@Vector(2, u64), @splat(2))) / 4;
            score1 = @max(score1, area);

            if (last_failed and area > last_area) {
                last_area = area;
                last_failed = true;
                continue;
            }

            last_failed = false;
            last_area = area;

            if (area < score2) continue;

            last_failed = true;

            if (p[0] == q[0] or p[1] == q[1]) continue; // area is basically 0

            const rect = makeRect(p, q);
            if (countIntersects(ys, y_pnts, rect.top, 0, rect.left) % 2 == 0) continue;

            if (intersects(ys, y_pnts, rect.top, rect.left, rect.right)) continue;
            if (intersects(ys, y_pnts, rect.bottom, rect.left, rect.right)) continue;
            if (intersects(xs, x_pnts, rect.left, rect.top, rect.bottom)) continue;
            if (intersects(xs, x_pnts, rect.right, rect.top, rect.bottom)) continue;

            last_failed = false;

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

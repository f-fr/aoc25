// Advent of code 25 - day 8
const std = @import("std");
const aoc = @import("aoc");

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    const Pnt = @Vector(3, i64);
    var pnts: std.ArrayList(Pnt) = .empty;

    while (try lines.next()) |line| {
        try pnts.append(a, try aoc.toNums(i32, 3, line, ","));
    }

    const n = pnts.items.len;
    const Edge = struct {
        u: usize,
        v: usize,
        l: f64,
        fn lessByLen(_: void, e: @This(), f: @This()) bool {
            return e.l < f.l;
        }
    };
    var lens = try a.alloc(Edge, n * (n - 1) / 2);
    {
        var e: usize = 0;
        for (pnts.items, 0..) |p, u| {
            for (pnts.items[u + 1 ..], u + 1..) |q, v| {
                const l = std.math.sqrt(@as(f64, @floatFromInt(@reduce(.Add, (p - q) * (p - q)))));
                lens[e] = .{
                    .u = u,
                    .v = v,
                    .l = l,
                };
                e += 1;
            }
        }
    }

    std.mem.sortUnstable(Edge, lens, {}, Edge.lessByLen);

    var components = try a.alloc(usize, n);
    for (0..n) |i| components[i] = i;

    const niter: usize = if (n < 100) 10 else 1000;

    var ncomponents: usize = n;
    var score1: u64 = 0;
    var score2: u64 = 0;
    for (lens, 1..) |e, i| {
        const cu = components[e.u];
        const cv = components[e.v];
        if (cu != cv) {
            for (components) |*other| {
                if (other.* == cv) other.* = cu;
            }

            ncomponents -= 1;
            if (ncomponents == 1) {
                score2 = @intCast(pnts.items[e.u][0] * pnts.items[e.v][0]);
                break;
            }
        }

        if (i == niter) {
            var sizes = try a.alloc(usize, n);
            defer a.free(sizes);
            @memset(sizes, 0);
            for (components) |c| sizes[c] += 1;
            aoc.sort(usize, sizes);
            score1 = sizes[n - 3] * sizes[n - 2] * sizes[n - 1];
        }
    }

    // now count the component sizes

    return .{ score1, score2 };
}

pub fn main() !void {
    var buffer: [2]u8 = undefined;
    const name = try std.fmt.bufPrint(&buffer, "{:02}", .{8});
    return aoc.run(name, run);
}

test "Day 8 part 1" {
    try aoc.run_tests(run, 8, 1);
}

test "Day 8 part 2" {
    try aoc.run_tests(run, 8, 2);
}

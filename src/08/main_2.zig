// Advent of code 25 - day 8
const std = @import("std");
const aoc = @import("aoc");

const UnionFind = struct {
    parent: []usize,
    rank: []usize,

    fn init(a: std.mem.Allocator, n: usize) !@This() {
        const p = try a.alloc(usize, n);
        const r = try a.alloc(usize, n);
        for (p, 0..) |*x, i| x.* = i;
        @memset(r, 0);
        return .{ .parent = p, .rank = r };
    }

    fn find(self: *@This(), u: usize) usize {
        const p = self.parent[u];
        if (p == u) return u;
        const new_p = self.find(p);
        self.parent[u] = new_p;
        return new_p;
    }

    fn union_(self: *@This(), u: usize, v: usize) bool {
        const pu = self.find(u);
        const pv = self.find(v);
        if (pu == pv) return false;
        if (self.rank[pu] > self.rank[pv]) {
            self.parent[pv] = pu;
        } else if (self.rank[pu] < self.rank[pv]) {
            self.parent[pu] = pv;
        } else {
            self.parent[pv] = pu;
            self.rank[pu] += 1;
        }
        return true;
    }
};

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

    var uf = try UnionFind.init(a, n);

    const niter: usize = if (n < 100) 10 else 1000;

    var ncomponents: usize = n;
    var score1: u64 = 0;
    var score2: u64 = 0;
    for (lens, 1..) |e, i| {
        if (uf.union_(e.u, e.v)) {
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
            for (0..n) |u| sizes[uf.find(u)] += 1;
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

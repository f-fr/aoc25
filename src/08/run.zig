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
        switch (std.math.order(self.rank[pu], self.rank[pv])) {
            .lt => self.parent[pu] = pv,
            .gt => self.parent[pv] = pu,
            .eq => {
                self.parent[pv] = pu;
                self.rank[pu] += 1;
            },
        }
        return true;
    }
};

const Elem = struct { len: u64, idx: usize };

fn downHeap(heap: []Elem, idx: usize) void {
    const x = heap[idx];
    var i = idx;
    var j = 2 * i + 1;
    while (j + 1 < heap.len) : (j = 2 * i + 1) {
        const k = j + @intFromBool(heap[j + 1].len < heap[j].len);
        if (heap[k].len >= x.len) break;
        heap[i] = heap[k];
        i = k;
    }
    if (j + 1 == heap.len and heap[j].len < heap[i].len) {
        heap[i] = heap[j];
        i = j;
    }
    heap[i] = x;
}

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
    var m = n * (n - 1) / 2;
    const Edge = [2]u16;

    var edges = try a.alloc(Edge, m);
    var lens = try a.alloc(Elem, m);
    {
        var e: usize = 0;
        for (pnts.items, 0..) |p, u| {
            for (pnts.items[u + 1 ..], u + 1..) |q, v| {
                edges[e] = .{ @intCast(u), @intCast(v) };
                lens[e] = .{
                    .idx = e,
                    .len = @intCast(@reduce(.Add, (p - q) * (p - q))),
                };
                e += 1;
            }
        }
    }

    for (m / 2..m) |i| downHeap(lens, m - i - 1);

    var uf = try UnionFind.init(a, n);
    var ncomponents: usize = n;

    const niter: usize = if (n < 100) 10 else 1000;
    var score1: u64 = 0;
    var score2: u64 = 0;
    var iter: usize = 0;

    while (m > 0) {
        iter += 1;

        const e_len = lens[0];
        m -= 1;
        lens[0] = lens[m];
        downHeap(lens[0..m], 0);

        const u = edges[e_len.idx][0];
        const v = edges[e_len.idx][1];

        if (uf.union_(u, v)) {
            ncomponents -= 1;

            if (ncomponents == 1) {
                score2 = @intCast(pnts.items[u][0] * pnts.items[v][0]);
                break;
            }
        }

        if (iter == niter) {
            var sizes = try a.alloc(usize, n);
            defer a.free(sizes);
            @memset(sizes, 0);
            for (0..n) |i| sizes[uf.find(i)] += 1;
            aoc.sort(usize, sizes);
            score1 = sizes[n - 3] * sizes[n - 2] * sizes[n - 1];
        }

    }

    return .{ score1, score2 };
}

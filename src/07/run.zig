const std = @import("std");
const aoc = @import("aoc");

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    var m: usize = 0;
    const s = start: while (try lines.next()) |line| {
        if (std.mem.findScalar(u8, line, 'S')) |j| {
            m = line.len;
            break :start j;
        }
    } else return error.MissingStart;

    var cur = try a.alloc(u64, m + 2);
    var nxt = try a.alloc(u64, m + 2);

    @memset(cur, 0);
    cur[s + 1] = 1;

    var score1: usize = 0;
    while (try lines.next()) |line| {
        if (line.len != m) return error.InvalidLineLen;

        @memset(nxt, 0);

        for (line, 1..) |c, j| {
            switch (c) {

                '.' => nxt[j] += cur[j],

                '^' => {
                    score1 += @intFromBool(cur[j] > 0);

                    nxt[j - 1] += cur[j];
                    nxt[j + 1] += cur[j];
                },

                else => return error.InvalidChar,
            }
        }

        std.mem.swap([]u64, &cur, &nxt);
    }

    var score2: u64 = 0;
    for (cur) |x| score2 += x;

    return .{ score1, score2 };
}

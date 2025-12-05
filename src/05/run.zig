const std = @import("std");
const aoc = @import("aoc");

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    const F = 4;
    var nums: std.ArrayList(u64) = .empty;
    while (try lines.next()) |line| {
        if (line.len == 0) break; // stop at the first empty line
        const ns = try aoc.toNums(u64, 2, line, "-");
        try nums.append(a, ns[0] * F); // opening
        try nums.append(a, ns[1] * F + 2); // closing
        if (ns[0] > ns[1]) return error.InvalidRange;
    }

    while (try lines.next()) |line| {
        const id = try aoc.toNum(u64, line);
        try nums.append(a, id * F + 1); // id
    }

    aoc.sort(u64, nums.items);

    var score1: usize = 0;
    var score2: u64 = 0;
    var nopen: usize = 0;
    var start: u64 = 0;
    for (nums.items) |x| {

        if (x % F == 0) {
            if (nopen == 0) start = x / F;
            nopen += 1;

        } else if (x % F == 2) {
            nopen -= 1;
            if (nopen == 0) score2 += (x / F - start + 1);

        } else if (nopen > 0) {
            score1 += 1;
        }
    }

    return .{ score1, score2 };
}

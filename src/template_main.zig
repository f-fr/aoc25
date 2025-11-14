// Advent of code 25 - day DAY
const std = @import("std");
const aoc = @import("aoc");

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    while (try lines.next()) |line| {
        _ = line;
        // TODO
    }

    return .{ 0, 0 };
}

pub fn main() !void {
    return aoc.run("DAY", run);
}

test "Day DAY part 1" {
    try aoc.run_tests(run, DAY, 1);
}

test "Day DAY part 2" {
    try aoc.run_tests(run, DAY, 2);
}

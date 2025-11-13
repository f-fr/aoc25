// Advent of code 23 - day DAY
const std = @import("std");
const aoc = @import("aoc");

pub fn run(lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(aoc.allocator);
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
    const EXAMPLE1 =
        \\TODO
    ;
    const PART1: u64 = 42;

    const scores = try aoc.run_test(run, EXAMPLE1);
    try std.testing.expectEqual(PART1, scores[0]);
}

test "Day DAY part 2" {
    const EXAMPLE2 =
        \\TODO
    ;
    const PART2: u64 = 42;

    const scores = try aoc.run_test(run, EXAMPLE2);
    try std.testing.expectEqual(PART2, scores[1]);
}

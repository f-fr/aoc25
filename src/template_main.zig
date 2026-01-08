// Advent of code 25 - day DAY
const std = @import("std");
const aoc = @import("aoc");

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    _ = a;

    while (try lines.next()) |line| {
        _ = line;
        // TODO
    }

    return .{ 0, 0 };
}

pub fn main(init: std.process.Init.Minimal) !void {
    var buffer: [2]u8 = undefined;
    const name = try std.fmt.bufPrint(&buffer, "{:02}", .{9});
    return aoc.run(name, init.args.iterate(), run);
}

test "Day DAY part 1" {
    try aoc.run_tests(run, DAY, 1);
}

test "Day DAY part 2" {
    try aoc.run_tests(run, DAY, 2);
}

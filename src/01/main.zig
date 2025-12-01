// Advent of code 25 - day 1
const std = @import("std");
const aoc = @import("aoc");

pub const run = @import("./run.zig").run;

pub fn main() !void {
    var buffer: [2]u8 = undefined;
    const name = try std.fmt.bufPrint(&buffer, "{:02}", .{1});
    return aoc.run(name, run);
}

test "Day 1 part 1" {
    try aoc.run_tests(run, 1, 1);
}

test "Day 1 part 2" {
    try aoc.run_tests(run, 1, 2);
}

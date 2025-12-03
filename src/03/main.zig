// Advent of code 25 - day 3
const std = @import("std");
const aoc = @import("aoc");

pub const run = @import("./run.zig").run;

pub fn main() !void {
    var buffer: [2]u8 = undefined;
    const name = try std.fmt.bufPrint(&buffer, "{:02}", .{3});
    return aoc.run(name, run);
}

test "Day 3 part 1" {
    try aoc.run_tests(run, 3, 1);
}

test "Day 3 part 2" {
    try aoc.run_tests(run, 3, 2);
}

// Advent of code 25 - day 7
const std = @import("std");
const aoc = @import("aoc");

pub const run = @import("./run.zig").run;

pub fn main() !void {
    var buffer: [2]u8 = undefined;
    const name = try std.fmt.bufPrint(&buffer, "{:02}", .{7});
    return aoc.run(name, run);
}

test "Day 7 part 1" {
    try aoc.run_tests(run, 7, 1);
}

test "Day 7 part 2" {
    try aoc.run_tests(run, 7, 2);
}

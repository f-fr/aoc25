// Advent of code 25 - day 11
const std = @import("std");
const aoc = @import("aoc");

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    var names = aoc.NamesBag(u32).init(a);
    var out_neighs: std.ArrayList(std.ArrayList(u32)) = .empty;

    while (try lines.next()) |line| {
        var toks = std.mem.tokenizeAny(u8, line, ": ");
        const u = try names.getOrPut(toks.next() orelse continue);
        while (u >= out_neighs.items.len) try out_neighs.append(a, .empty);
        while (toks.next()) |tok| {
            const v = try names.getOrPut(tok);
            try out_neighs.items[u].append(a, v);
        }
    }

    const n = names.count();
    while (out_neighs.items.len < n) try out_neighs.append(a, .empty);

    var degrees = try a.alloc(usize, n);
    @memset(degrees, 0);
    for (out_neighs.items) |outs| {
        for (outs.items) |v| degrees[v] += 1;
    }

    // top sort
    const top_order = top_sort: {
        var q: std.Deque(u32) = .empty;
        defer q.deinit(a);
        try q.ensureTotalCapacity(a, n);

        for (degrees, 0..) |deg, u| if (deg == 0) q.pushBackAssumeCapacity(@intCast(u));
        var top_order: std.ArrayList(u32) = .empty;
        while (q.popFront()) |u| {
            try top_order.append(a, u);
            for (out_neighs.items[u].items) |v| {
                degrees[v] -= 1;
                if (degrees[v] == 0) try q.pushBack(a, v);
            }
        }
        break :top_sort try top_order.toOwnedSlice(a);
    };

    var cnts = try a.alloc(u64, n);
    const out = names.getOrNull("out") orelse return error.MissingOut;
    var score1: u64 = 0;
    if (names.getOrNull("you")) |you| {
        @memset(cnts, 0);
        cnts[you] = 1;
        for (top_order) |u| {
            for (out_neighs.items[u].items) |v| cnts[v] += cnts[u];
        }
        score1 = cnts[out];
    }

    var score2: u64 = 1;
    if (names.getOrNull("svr")) |svr| {
        const fft = names.getOrNull("fft") orelse return error.MissingFft;
        const dac = names.getOrNull("dac") orelse return error.MissingDac;

        // one of both is first because of the topological order
        const v1, const v2 = if (top_order[std.mem.findAny(u32, top_order, &.{ fft, dac }).?] == fft) .{ fft, dac } else .{ dac, fft };

        inline for (.{ .{ svr, v1 }, .{ v1, v2 }, .{ v2, out } }) |st| {
            @memset(cnts, 0);
            cnts[st[0]] = 1;
            for (top_order) |u| {
                for (out_neighs.items[u].items) |v| cnts[v] += cnts[u];
            }
            score2 *= cnts[st[1]];
        }
    }

    return .{ score1, score2 };
}

pub fn main() !void {
    var buffer: [2]u8 = undefined;
    const name = try std.fmt.bufPrint(&buffer, "{:02}", .{11});
    return aoc.run(name, run);
}

test "Day 11 part 1" {
    try aoc.run_tests(run, 11, 1);
}

test "Day 11 part 2" {
    try aoc.run_tests(run, 11, 2);
}

// Advent of code 25 - day 10
const std = @import("std");
const aoc = @import("aoc");

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    var score1: u64 = 0;
    var iter: usize = 0;
    while (try lines.next()) |line| {
        const light_end = std.mem.findScalar(u8, line, ']') orelse return error.InvalidLights;
        const buttons_end = (std.mem.findScalarPos(u8, line, light_end, '{') orelse return error.InvalidButtons);

        var light: u16 = 0;
        for (line[1..light_end], 0..) |c, i| light |= @as(u16, @intFromBool(c == '#')) << @as(u4, @intCast(i));

        var buttons: std.ArrayList(u16) = .empty;
        defer buttons.deinit(a);
        var tok_it = std.mem.tokenizeScalar(u8, line[light_end + 1 .. buttons_end], ' ');
        while (tok_it.next()) |tok| {
            var l_it = std.mem.tokenizeScalar(u8, tok[1 .. tok.len - 1], ',');
            var button: u16 = 0;
            while (l_it.next()) |l| button |= @as(u16, 1) << try aoc.toNum(u4, l);
            try buttons.append(a, button);
        }

        // for (buttons.items) |b| std.debug.print(" {b:06}", .{b});
        // std.debug.print("\n", .{});

        const joltages = try aoc.toNumsAnyA(u16, a, line[buttons_end + 1 ..], ",}");
        defer a.free(joltages);

        // std.debug.print("{any}\n", .{joltages});

        var q: std.Deque(u16) = .empty;
        defer q.deinit(a);
        const dist = try a.alloc(?u16, 1024);
        defer a.free(dist);
        @memset(dist, null);
        dist[0] = 0;
        try q.pushBack(a, 0);
        while (q.popFront()) |u| {
            const d = dist[u].?;
            // std.debug.print("visit {b} dist:{}\n", .{ u, d });
            if (u == light) break;
            for (buttons.items) |b| {
                const v = u ^ b;
                if (dist[v] == null) {
                    dist[v] = d + 1;
                    // std.debug.print("  {b} → {b}\n", .{ u, v });
                    try q.pushBack(a, v);
                }
            }
        }
        score1 += dist[light].?;
        // std.debug.print("---------- dist:{} ------\n", .{dist[light].?});

        iter += 1;
        const filename = try std.fmt.allocPrint(a, "m{}.zpl", .{iter});
        defer a.free(filename);
        var file = try std.fs.cwd().createFile(filename, .{});
        var buf: [1024]u8 = undefined;
        var writer = file.writer(&buf);
        var w = &writer.interface;
        try w.print("set I := {{1 .. {}}};\n", .{buttons.items.len});
        _ = try w.write("var X[I] integer >= 0;\n");
        _ = try w.write("minimize obj: sum <i> in I: X[i];\n");
        for (joltages, 0..) |j_level, j| {
            try w.print("subto light{}:\n", .{j + 1});
            _ = try w.write("    0");
            for (buttons.items, 0..) |b, i| {
                try w.print(" + {} * X[{}]", .{ @intFromBool(b & (@as(u16, 1) << @as(u4, @intCast(j))) != 0), i + 1 });
            }
            try w.print(" == {};\n", .{j_level});
        }
        try w.flush();
        file.close();
    }

    return .{ score1, 0 };
}

pub fn main() !void {
    var buffer: [2]u8 = undefined;
    const name = try std.fmt.bufPrint(&buffer, "{:02}", .{10});
    return aoc.run(name, run);
}

test "Day 10 part 1" {
    try aoc.run_tests(run, 10, 1);
}

test "Day 10 part 2" {
    try aoc.run_tests(run, 10, 2);
}

// Advent of code 25 - day 12
const std = @import("std");
const aoc = @import("aoc");

const Tile = [3][3]bool;

fn tile2num(tile: Tile) u9 {
    var x: u9 = 0;
    for (tile) |row| {
        for (row) |c| {
            x = (x << 1) | @intFromBool(c);
        }
    }
    return x;
}

fn num2tile(x: u9) Tile {
    var tile: Tile = undefined;
    var off: u4 = 9;
    for (0..3) |i| {
        for (0..3) |j| {
            off -= 1;
            tile[i][j] = (x >> off) & 1 != 0;
        }
    }
    return tile;
}

fn rotateLeft(tile: Tile) Tile {
    var result: Tile = undefined;
    for (0..tile.len) |i| {
        for (0..tile[i].len) |j| {
            result[tile.len - j - 1][i] = tile[i][j];
        }
    }
    return result;
}

fn mirror(tile: Tile) Tile {
    var result = tile;
    std.mem.reverse([3]bool, &result);
    return result;
}

pub fn run(alloc: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    var tiles: std.ArrayList(Tile) = .empty;

    const Square = struct {
        width: usize,
        height: usize,
        amounts: [6]usize,
    };
    var sqrs: std.ArrayList(Square) = .empty;

    var tile: Tile = undefined;
    var tile_line: usize = 0;
    while (try lines.next()) |line| {
        const l = aoc.trim(line);
        if (l.len == 0) {
            // next tile
            try tiles.append(a, tile);
            tile_line = 0;
            continue;
        }
        if (std.mem.findScalar(u8, l, 'x') != null) {
            // square line
            var toks = try aoc.toNumsAny(usize, 8, l, "x: ");
            try sqrs.append(a, .{
                .width = toks[0],
                .height = toks[1],
                .amounts = toks[2..].*,
            });
        } else if (std.mem.findScalar(u8, l, ':') != null) {
            // number of tile line -> ignore
        } else {
            // tile line
            for (l, 0..) |c, j| tile[tile_line][j] = c == '#';
            tile_line += 1;
        }
    }

    const sizes = try a.alloc(usize, tiles.items.len);
    for (tiles.items, sizes) |tl, *s| {
        s.* = 0;
        for (tl) |row| {
            for (row) |c| s.* += @intFromBool(c);
        }
    }

    const rotated_tiles = try a.alloc([]Tile, tiles.items.len);
    for (tiles.items, rotated_tiles) |tl, *rtiles| {
        var t = tl;
        var all_rtiles: [8]u9 = undefined;
        for (0..4) |i| {
            all_rtiles[i] = tile2num(t);
            t = rotateLeft(t);
        }
        t = mirror(t);
        for (4..8) |i| {
            all_rtiles[i] = tile2num(t);
            t = rotateLeft(t);
        }
        aoc.sort(u9, &all_rtiles);
        const unique_tiles = aoc.unique(u9, &all_rtiles);
        const result = try a.alloc(Tile, unique_tiles.len);
        for (unique_tiles, result) |from, *to| {
            to.* = num2tile(from);
        }
        rtiles.* = result;
    }

    var io: std.Io.Threaded = .init_single_threaded;
    defer io.deinit();

    var n_feasible: usize = 0;
    var n_infeasible: usize = 0;
    for (sqrs.items, 1..) |sqr, sqr_idx| {
        var min_required: usize = 0;
        var max_required: usize = 0;
        for (sqr.amounts, sizes) |amount, size| {
            min_required += amount * size;
            max_required += amount * 9;
        }

        if (max_required <= sqr.width * sqr.height) {
            n_feasible += 1;
            continue;
        }
        if (min_required > sqr.width * sqr.height) {
            n_infeasible += 1;
            continue;
        }

        const filename = try std.fmt.allocPrint(a, "sqr{}.zpl", .{sqr_idx});
        defer a.free(filename);

        var file = try std.Io.Dir.cwd().createFile(io.io(), filename, .{});
        defer file.close(io.io());
        var buf: [1024]u8 = undefined;
        var writer = file.writer(io.io(), &buf);
        var wr = &writer.interface;
        defer wr.flush() catch {};

        const w = sqr.width;
        const h = sqr.height;
        try wr.print("set T := {{0 .. {}}};\n", .{rotated_tiles.len - 1});
        try wr.print("set R := {{1 .. 8}};\n", .{});
        try wr.print("set I := {{1 .. {}}};\n", .{h - 2});
        try wr.print("set J := {{1 .. {}}};\n", .{w - 2});
        try wr.print("var X[T * I * J * R] binary;\n", .{});

        for (0..h) |i| {
            for (0..w) |j| {
                try wr.print("subto field_{}_{}:\n", .{ i + 1, j + 1 });
                try wr.print("    0", .{});
                for (@max(i, 2) - 2..@min(i + 1, h - 2)) |ii| {
                    for (@max(j, 2) - 2..@min(j + 1, w - 2)) |jj| {
                        // (ii, jj) is the top left corner of a piece potentially covering (i,j)
                        for (rotated_tiles, 0..) |rtiles, t_idx| {
                            for (rtiles, 1..) |t, r| {
                                if (t[i - ii][j - jj]) {
                                    try wr.print(" +\n    X[{},{},{},{}]", .{ t_idx, ii + 1, jj + 1, r });
                                }
                            }
                        }
                    }
                }
                try wr.print(" <= 1;\n", .{});
            }
        }

        for (sqr.amounts, 0..) |amount, t_idx| {
            try wr.print("subto amount_{}:\n", .{t_idx});
            try wr.print("    0", .{});
            for (0..h - 2) |ii| {
                for (0..w - 2) |jj| {
                    for (1..rotated_tiles[t_idx].len + 1) |r| {
                        try wr.print(" +\n    X[{},{},{},{}]", .{ t_idx, ii + 1, jj + 1, r });
                    }
                }
            }
            try wr.print(" == {};\n", .{amount});
        }
    }

    return .{ n_feasible, 0 };
}

pub fn main() !void {
    var buffer: [2]u8 = undefined;
    const name = try std.fmt.bufPrint(&buffer, "{:02}", .{12});
    return aoc.run(name, run);
}

test "Day 12 part 1" {
    try aoc.run_tests(run, 12, 1);
}

test "Day 12 part 2" {
    try aoc.run_tests(run, 12, 2);
}

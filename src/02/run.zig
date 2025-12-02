const std = @import("std");
const aoc = @import("aoc");

const powi = std.math.powi;

pub fn run(allocator: std.mem.Allocator, lines: *aoc.Lines) ![2]u64 {
    lines.delimiter = ',';

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var score1: u64 = 0;
    // invalid ids for part 2
    var invalids: std.ArrayList(u64) = .empty;

    while (try lines.next()) |rng| {
        const toks = try aoc.splitN(2, std.mem.trim(u8, rng, " \t\r\n"), "-");

        const d1 = toks[0].len;
        const d2 = toks[1].len;

        const x = try std.fmt.parseUnsigned(u64, toks[0], 10);
        const y = try std.fmt.parseUnsigned(u64, toks[1], 10);

        for (1..d2 / 2 + 1) |d| {

            const f = try powi(u64, 10, d); // block size as 10^d

            const k_min = @max(2, (d1 - 1) / d + 1); // minimal number of blocks
            const k_max = d2 / d; // maximal number of blocks

            for (k_min..k_max + 1) |k| {

                // block multiplicator
                const q = (try powi(u64, f, k) - 1) / (f - 1);

                // minimal value based on x and on block-size (no leading zeros)
                const a = @max((x - 1) / q + 1, f / 10);
                // maximal value based on y and on block-size (no leading zeros)
                const b = @min(y / q, f - 1);

                if (a > b) continue;

                if (k == 2) {
                    // all values in between match (hopefully)
                    score1 += (b * (b + 1) - a * (a - 1)) / 2 * q;
                }

                // because there may be duplicates, we simply count
                var z = a;
                while (z <= b) : (z += 1) try invalids.append(alloc, z * q);
            }
        }
    }

    aoc.sort(u64, invalids.items);
    var score2: u64 = if (invalids.items.len == 0) 0 else invalids.items[0];
    for (invalids.items[0 .. invalids.items.len - 1], invalids.items[1..]) |x, y| {
        if (x != y) score2 += y;
    }

    return .{ score1, score2 };
}

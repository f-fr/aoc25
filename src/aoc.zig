const std = @import("std");
const testing = std.testing;
const search = @import("./search.zig");

pub const GenArray = @import("./genary.zig").GenArray;
pub const Search = search.Search;
pub const SearchWithSeen = search.SearchWithSeen;
pub const PriQueue = @import("./priqueue.zig").PriQueue;
pub const NamesBag = @import("./namesbag.zig").NamesBag;

//pub var allocator_instance = std.heap.GeneralPurposeAllocator(.{}){};
// 50 MiB of memory for dynamic allocation
var mem_buffer: [1024 * 1024 * 20]u8 = undefined;
pub var allocator_instance = std.heap.FixedBufferAllocator.init(&mem_buffer);
pub var allocator = if (@import("builtin").is_test) testing.allocator else allocator_instance.allocator();

pub const Err = error{
    MissingProgramName,
    InvalidProgramName,
    InvalidInstanceNumber,
};

pub const SplitErr = error{
    TooManyElementsForSplit,
    TooFewElementsForSplit,
};

pub const Dir = enum {
    north,
    west,
    south,
    east,

    pub fn reverse(self: Dir) Dir {
        return switch (self) {
            .north => .south,
            .south => .north,
            .east => .west,
            .west => .east,
        };
    }
};

pub const Dirs = std.enums.values(Dir);

pub const Pos = PosT(usize);
pub fn PosT(comptime T: type) type {
    return struct {
        const Self = @This();

        i: T = 0,
        j: T = 0,

        pub fn eql(a: Self, b: Self) bool {
            return a.i == b.i and a.j == b.j;
        }

        pub fn step(p: Self, dir: Dir) Self {
            return switch (dir) {
                .north => .{ .i = p.i - 1, .j = p.j },
                .west => .{ .i = p.i, .j = p.j - 1 },
                .south => .{ .i = p.i + 1, .j = p.j },
                .east => .{ .i = p.i, .j = p.j + 1 },
            };
        }

        pub fn stepn(p: Self, dir: Dir, n: T) Self {
            return switch (dir) {
                .north => .{ .i = p.i - n, .j = p.j },
                .west => .{ .i = p.i, .j = p.j - n },
                .south => .{ .i = p.i + n, .j = p.j },
                .east => .{ .i = p.i, .j = p.j + n },
            };
        }

        pub fn maybeStep(p: Self, dir: Dir, n: T, m: T) ?Self {
            return switch (dir) {
                .north => if (p.i > 0) .{ .i = p.i - 1, .j = p.j } else null,
                .west => if (p.j > 0) .{ .i = p.i, .j = p.j - 1 } else null,
                .south => if (p.i + 1 < n) .{ .i = p.i + 1, .j = p.j } else null,
                .east => if (p.j + 1 < m) .{ .i = p.i, .j = p.j + 1 } else null,
            };
        }

        pub fn dist1(a: Self, b: Self) T {
            return (if (a.i > b.i) a.i - b.i else b.i - a.i) +
                (if (a.j > b.j) a.j - b.j else b.j - a.j);
        }
    };
}

pub const Grid = GridT(u8);

pub fn GridT(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Number of rows
        n: usize = 0,
        /// Number of columns
        m: usize = 0,
        /// The data in row-major order
        data: []T = &[_]T{},

        pub fn init(alloc: std.mem.Allocator, n: usize, m: usize) !Self {
            const data = try alloc.alloc(T, n * m);
            return initBuffer(data, n, m);
        }

        pub fn initWith(alloc: std.mem.Allocator, n: usize, m: usize, c: T) !Self {
            var g = try init(alloc, n, m);
            g.setAll(c);
            return g;
        }

        pub fn initBuffer(buf: []T, n: usize, m: usize) Self {
            return Self{
                .n = n,
                .m = m,
                .data = buf[0 .. n * m],
            };
        }

        pub fn initBufferWith(buf: []T, n: usize, m: usize, c: T) Self {
            var g = try initBuffer(buf, n, m);
            g.setAll(c);
            return g;
        }

        pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
            alloc.free(self.data);
        }

        /// Return the linear offset of the element at (i, j).
        pub fn offset(grid: *const Self, i: usize, j: usize) usize {
            return grid.m * i + j;
        }

        /// Return the character at position (i, j)
        pub fn at(grid: *const Self, i: usize, j: usize) T {
            return grid.data[grid.offset(i, j)];
        }

        pub fn atPos(grid: *const Self, p: Pos) T {
            return grid.at(p.i, p.j);
        }

        /// Return the character at position (i, j)
        pub fn ref(grid: *Self, i: usize, j: usize) *T {
            return &grid.data[grid.offset(i, j)];
        }

        pub fn refPos(grid: *Self, p: Pos) *T {
            return grid.ref(p.i, p.j);
        }

        /// Return a slice to the ith row.
        pub fn row(grid: *const Self, i: usize) []T {
            return grid.data[grid.m * i .. grid.m * i + grid.m];
        }

        pub fn findFirst(grid: *const Self, ch: T) ?Pos {
            if (std.mem.indexOfScalar(u8, grid.data, ch)) |off| {
                return .{ .i = off / grid.m, .j = off % grid.m };
            }

            return null;
        }

        pub fn setAll(grid: *Self, c: T) void {
            @memset(grid.data, c);
        }

        pub fn set(grid: *Self, i: usize, j: usize, c: T) void {
            grid.data[grid.offset(i, j)] = c;
        }

        pub fn setPos(grid: *Self, p: Pos, c: T) void {
            grid.set(p.i, p.j, c);
        }

        pub fn dupe(grid: *const Self, alloc: std.mem.Allocator) !Self {
            return Self{
                .n = grid.n,
                .m = grid.m,
                .data = try alloc.dupe(T, grid.data),
            };
        }

        /// Rotate the grid 90 degrees counter clock wise and return
        /// the result as new grid.
        pub fn rotateLeft(grid: *const Self, alloc: std.mem.Allocator) !Self {
            var g = try Self.init(alloc, grid.m, grid.n);
            for (0..grid.n) |i| {
                for (0..grid.m) |j| {
                    g.set(grid.m - j - 1, i, grid.at(i, j));
                }
            }
            return g;
        }
    };
}

test "Grid.rotateLeft" {
    const data = "1234567890ab";
    var g = Grid.initBuffer(try testing.allocator.dupe(u8, data), 3, 4);
    defer g.deinit(testing.allocator);

    var g2 = try g.rotateLeft(testing.allocator);
    defer g2.deinit(testing.allocator);

    try testing.expectEqual(4, g2.n);
    try testing.expectEqual(3, g2.m);
    try testing.expectEqualSlices(u8, "48b", g2.row(0));
    try testing.expectEqualSlices(u8, "37a", g2.row(1));
    try testing.expectEqualSlices(u8, "260", g2.row(2));
    try testing.expectEqualSlices(u8, "159", g2.row(3));
}

const BufferType = enum { file, buffer };

pub const Lines = struct {
    reader: *std.Io.Reader,
    delimiter: u8 = '\n',

    pub fn init(reader: *std.Io.Reader) Lines {
        return .{ .reader = reader };
    }

    pub fn next(self: *Lines) !?[]const u8 {
        return self.reader.takeDelimiter(self.delimiter);
    }

    /// Read the whole file as a grid.
    ///
    /// The memory belongs to the caller.
    pub fn readGrid(self: *Lines, alloc: std.mem.Allocator) !Grid {
        return try readNextGrid(self, alloc) orelse error.UnexpectedEndOfFile;
    }

    /// Read the next lines of a file (until an empty line or eof) as a grid.
    ///
    /// All lines must have the same length.
    ///
    /// The memory belongs to the caller.
    pub fn readNextGrid(self: *Lines, alloc: std.mem.Allocator) !?Grid {
        var data: std.ArrayList(u8) = .empty;
        defer data.deinit(alloc);

        var n: usize = 0;
        var m: usize = 0;
        while (try self.next()) |line| {
            if (line.len == 0) break;
            if (m == 0) {
                m = line.len;
                // assume that the grid is quadratic
                try data.ensureTotalCapacity(alloc, m * m);
            } else if (m != line.len)
                return error.InvalidRowLength;
            try data.appendSlice(alloc, line);
            n += 1;
        }

        if (m == 0) return null;

        return .{ .n = n, .m = m, .data = try data.toOwnedSlice(alloc) };
    }

    /// Read the whole file as a grid and add an additional boundary
    /// character `boundary` around the field.
    ///
    /// All lines must have the same length.
    ///
    /// The memory belongs to the caller.
    pub fn readGridWithBoundary(self: *Lines, alloc: std.mem.Allocator, boundary: u8) !Grid {
        return try readNextGridWithBoundary(self, alloc, boundary) orelse error.UnexpectedEndOfFile;
    }

    /// Read the next lines as a grid and add an additional boundary
    /// character `boundary` around the field.
    ///
    /// The grid ends at the next empty line or eof.
    /// Returns `null` if there is no further grid.
    ///
    /// The memory belongs to the caller.
    pub fn readNextGridWithBoundary(self: *Lines, alloc: std.mem.Allocator, boundary: u8) !?Grid {
        var data: std.ArrayList(u8) = .empty;
        defer data.deinit(alloc);

        var n: usize = 2;
        var m: usize = 0;
        while (try self.next()) |line| {
            if (line.len == 0) break;
            if (m == 0) {
                m = line.len + 2;
                // assume that the grid is quadratic (but at most 100 lines)
                try data.ensureTotalCapacity(alloc, m * @min(100, m));
                try data.appendNTimes(alloc, boundary, m);
            } else if (m != line.len + 2)
                return error.InvalidRowLength;
            try data.append(alloc, boundary);
            try data.appendSlice(alloc, line);
            try data.append(alloc, boundary);
            n += 1;
        }

        if (m == 0) return null;

        try data.appendNTimes(alloc, boundary, m);

        return .{ .n = n, .m = m, .data = try data.toOwnedSlice(alloc) };
    }

    /// Read the whole file as a grid.
    ///
    /// The width of the grid will be determined by the longest line.
    /// Shorter lines will be filled with a `fill` character.
    ///
    /// The memory belongs to the caller.
    pub fn readGridFilled(self: *Lines, alloc: std.mem.Allocator, fill: u8) !Grid {
        return try readNextGridFilled(self, alloc, fill) orelse error.UnexpectedEndOfFile;
    }

    /// Read the next lines of a file (until an empty line or eof) as a grid.
    ///
    /// The width of the grid will be determined by the longest line.
    /// Shorter lines will be filled with a `fill` character.
    ///
    /// The memory belongs to the caller.
    pub fn readNextGridFilled(self: *Lines, alloc: std.mem.Allocator, fill: u8) !?Grid {
        // As long as lines get only smaller, we do not need to allocate
        // memory for each line separately. Instead we use the same
        // strategy as `readNextGrid` and read everything in one
        // single continuous array (which may be resized).
        var data: std.ArrayList(u8) = .empty;
        defer data.deinit(alloc);

        // The list of lines (needed only if the lines get longer).
        // The memory of the `nfirst` lines will be contained in `data`.
        var nfirst: usize = 0;
        var lines: std.ArrayList([]u8) = .empty;
        defer if (lines.items.len > 0) {
            for (lines.items[nfirst..]) |l| alloc.free(l);
            lines.deinit(alloc);
        };

        var n: usize = 0;
        var m: usize = 0;
        while (try self.next()) |line| {
            if (line.len == 0) break;
            if (lines.items.len == 0) {
                if (m == 0) {
                    // the first line, assume the grid is a square (but at most 100 lines)
                    m = line.len;
                    try data.ensureTotalCapacity(alloc, m * @min(100, m));
                }
                if (line.len <= m) {
                    try data.appendSlice(alloc, line);
                    try data.appendNTimes(alloc, fill, m - line.len);
                    nfirst += 1;
                } else {
                    // This line is longer than the previous lines.
                    // We switch to single-line mode.
                    try lines.ensureTotalCapacity(alloc, 2 * (n + 1));
                    // Add the existing lines (the first `nfirst` lines are managed
                    // by `data`).
                    for (0..n) |i| {
                        lines.appendAssumeCapacity(data.items[i * m .. i * m + m]);
                    }
                    // add the new line
                    lines.appendAssumeCapacity(try alloc.dupe(u8, line));
                    m = line.len;
                }
            } else {
                // single-line mode, just append the new line
                m = @max(m, line.len);
                try lines.append(alloc, try alloc.dupe(u8, line));
            }
            n += 1;
        }

        if (m == 0) return null;

        if (lines.items.len == 0) {
            return .{
                .n = n,
                .m = m,
                .data = try data.toOwnedSlice(alloc),
            };
        } else {
            const res = try alloc.alloc(u8, n * m);
            for (lines.items, 0..) |l, i| {
                @memcpy(res[i * m .. i * m + l.len], l);
                @memset(res[i * m + l.len .. i * m + m], fill);
            }
            return .{ .n = n, .m = m, .data = res };
        }
    }
};

test "readNextGridFilled equal lines" {
    const input =
        \\12345
        \\45678
        \\90abc
        \\
        \\xxx
    ;
    var r = std.Io.Reader.fixed(input);
    var lines = Lines.init(&r);
    var g = (try lines.readNextGridFilled(testing.allocator, '.')).?;
    defer g.deinit(testing.allocator);
    try testing.expectEqual(3, g.n);
    try testing.expectEqual(5, g.m);
    try testing.expectEqualSlices(u8, "12345", g.row(0));
    try testing.expectEqualSlices(u8, "45678", g.row(1));
    try testing.expectEqualSlices(u8, "90abc", g.row(2));
}

test "readNextGridFilled non equal lines" {
    const input =
        \\123
        \\45678
        \\90
        \\
        \\xxx
    ;
    var r = std.Io.Reader.fixed(input);
    var lines = Lines.init(&r);
    var g = (try lines.readNextGridFilled(testing.allocator, '.')).?;
    defer g.deinit(testing.allocator);
    try testing.expectEqual(3, g.n);
    try testing.expectEqual(5, g.m);
    try testing.expectEqualSlices(u8, "123..", g.row(0));
    try testing.expectEqualSlices(u8, "45678", g.row(1));
    try testing.expectEqualSlices(u8, "90...", g.row(2));
}

test "readNextGridFilled with lines getting shorter" {
    const input =
        \\12345
        \\4567
        \\90a
        \\
        \\xxx
    ;
    var r = std.Io.Reader.fixed(input);
    var lines = Lines.init(&r);
    var g = (try lines.readNextGridFilled(testing.allocator, '.')).?;
    defer g.deinit(testing.allocator);
    try testing.expectEqual(3, g.n);
    try testing.expectEqual(5, g.m);
    try testing.expectEqualSlices(u8, "12345", g.row(0));
    try testing.expectEqualSlices(u8, "4567.", g.row(1));
    try testing.expectEqualSlices(u8, "90a..", g.row(2));
}

pub fn getInstanceFileName(buf: []u8, instance: ?usize) ![]u8 {
    var args = std.process.args();
    const program = args.next() orelse return Err.MissingProgramName;
    const end = std.mem.indexOfScalar(u8, program, '_') orelse program.len;
    const day = std.fmt.parseInt(u8, std.fs.path.basename(program[0..end]), 10) catch return Err.InvalidProgramName;

    const inst = instance orelse fromarg: {
        const inst = args.next() orelse "1";
        const i = std.fmt.parseInt(usize, inst, 10) catch return Err.InvalidInstanceNumber;
        break :fromarg i;
    };

    return std.fmt.bufPrint(buf, "input/{d:0>2}/input{}.txt", .{ day, inst });
}

pub fn run(name: []const u8, comptime runfn: anytype) !void {
    info("AoC23 - day {s}", .{name});
    var buffer: [64 * 1024]u8 = undefined;
    const filename = try getInstanceFileName(&buffer, null);
    var file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();
    var io: std.Io.Threaded = std.Io.Threaded.init_single_threaded;
    var reader = file.reader(io.io(), &buffer);
    try reader.interface.fillMore();
    var lines = Lines.init(&reader.interface);
    var timer = try std.time.Timer.start();
    const scores = try runfn(allocator, &lines);
    const t_end = timer.lap();

    println("Part 1: {}", .{scores[0]});
    println("Part 2: {}", .{scores[1]});
    println("Time  : {d:.3}", .{@as(f64, @floatFromInt(t_end)) / 1e9});
}

fn run_test(runfunc: anytype, reader: *std.Io.Reader, part: u8, both_parts: bool) !void {
    std.debug.assert(part >= 1 and part <= 2);

    var lines = Lines.init(reader);
    const expected_line = try lines.next() orelse return error.MissingExpectedLine;

    if (!std.mem.startsWith(u8, expected_line, "EXPECTED:")) return error.InvalidExpectedLine;

    var toks = std.mem.tokenizeAny(u8, expected_line[9..], " \t");
    const expected_score1_str = toks.next() orelse return error.MissingExpectedValue;
    const expected_score2_str = toks.next();

    // do not run a test on part 2 if there is only an expected result for part 1
    if (part == 2 and both_parts and expected_score2_str == null) return;

    const expected_score1 = try std.fmt.parseInt(u64, expected_score1_str, 10);
    const expected_score2 = if (expected_score2_str) |s| try std.fmt.parseInt(u64, s, 10) else expected_score1;
    const expected_scores = [2]u64{ expected_score1, expected_score2 };

    const scores = try runfunc(testing.allocator, &lines);

    return std.testing.expectEqual(expected_scores[part - 1], scores[part - 1]);
}

pub fn run_tests(runfunc: anytype, day: u8, part: u8) !void {
    const io = std.testing.io;

    var buffer: [1024]u8 = undefined;
    const path = try std.fmt.bufPrint(&buffer, "input/{:02}", .{day});

    var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
    defer dir.close();
    var dir_it = dir.iterate();
    while (try dir_it.next()) |d| {
        if (std.mem.startsWith(u8, d.name, "test") and std.mem.endsWith(u8, d.name, ".txt")) {
            var both_parts = true;
            if (std.mem.startsWith(u8, d.name[4..], "_part")) {
                const end = if (std.mem.findAny(u8, d.name[9..], "_.")) |i| i + 9 else d.name.len;
                const p = try std.fmt.parseInt(u32, d.name[9..end], 10);
                // test case is not for this part -> skip
                if (p != part) continue;
                both_parts = false;
            }
            // run this test case
            var file = try dir.openFile(d.name, .{ .mode = .read_only });
            defer file.close();
            var reader = file.reader(io, &buffer);
            try run_test(runfunc, &reader.interface, part, both_parts);
        }
    }
}

pub fn run_times(comptime days: anytype) !void {
    var t_total: f64 = 0;
    var t_day: f64 = 0;
    var cur_day: usize = 0;
    var timer = try std.time.Timer.start();
    var buffer: [4096]u8 = undefined;
    var io: std.Io.Threaded = std.Io.Threaded.init_single_threaded;
    inline for (days) |day| {
        var file = try std.fs.cwd().openFile(day.filename, .{ .mode = .read_only });
        defer file.close();
        var reader = file.reader(io.io(), &buffer);
        var lines = Lines.init(&reader.interface);

        timer.reset();
        const s = try day.run(allocator, &lines);
        const t_end = timer.lap();
        const t = @as(f64, @floatFromInt(t_end)) / 1e9;
        if (cur_day != day.day) {
            t_total += t_day;
            t_day = t;
        } else t_day = @min(t_day, t);
        cur_day = day.day;

        if (day.version.len == 0)
            println("Day {d:0>2}   : {d:.3} -- part 1: {d: >15}   part 2: {d: >15}", .{ day.day, t, s[0], s[1] })
        else
            println("Day {d:0>2} v{s}: {d:.3} -- part 1: {d: >15}   part 2: {d: >15}", .{ day.day, day.version, t, s[0], s[1] });
    }
    t_total += t_day; // last day
    println("Total time (best versions): {d:.3}", .{t_total});
}

pub const info = std.log.info;

pub const print = std.debug.print;

pub fn println(comptime format: []const u8, args: anytype) void {
    print(format ++ "\n", args);
}

pub fn trim(s: []const u8) []const u8 {
    return std.mem.trim(u8, s, " \t\r\n");
}

fn genSplitN(comptime N: usize, s: []const u8, separator: []const u8, comptime tokenize: anytype) ![N][]const u8 {
    if (N == 1) return .{s};

    var result: [N][]const u8 = undefined;
    var toks = tokenize(u8, s, separator);
    var i: usize = 0;
    while (toks.next()) |tok| {
        result[i] = tok;
        i += 1;
        if (i + 1 == N) break;
    }
    result[i] = toks.rest();
    i += 1;
    while (i < N) : (i += 1) {
        result[i] = "";
    }

    return result;
}

pub fn splitN(comptime N: usize, s: []const u8, separator: []const u8) ![N][]const u8 {
    return genSplitN(N, s, separator, std.mem.tokenizeSequence);
}

pub fn splitAnyN(comptime N: usize, s: []const u8, separator: []const u8) ![N][]const u8 {
    return genSplitN(N, s, separator, std.mem.tokenizeAny);
}

test "splitN" {
    for (try splitN(6, "A B C D E F", " "), [_][]const u8{ "A", "B", "C", "D", "E", "F" }) |a, b| try testing.expectEqualSlices(u8, a, b);
    for (try splitN(6, "A B C D E F G", " "), [_][]const u8{ "A", "B", "C", "D", "E", "F G" }) |a, b| try testing.expectEqualSlices(u8, a, b);
    for (try splitN(6, "A B C D E", " "), [_][]const u8{ "A", "B", "C", "D", "E", "" }) |a, b| try testing.expectEqualSlices(u8, a, b);
}

fn genSplitA(alloc: std.mem.Allocator, s: []const u8, separator: []const u8, comptime tokenize: anytype) ![][]const u8 {
    var result: std.ArrayList([]const u8) = .empty;
    errdefer result.deinit(alloc);

    var toks = tokenize(u8, s, separator);
    var i: usize = 0;
    while (toks.next()) |tok| {
        try result.append(alloc, tok);
        i += 1;
    }

    return try result.toOwnedSlice(alloc);
}

pub fn splitA(alloc: std.mem.Allocator, s: []const u8, separator: []const u8) ![][]const u8 {
    return genSplitA(alloc, s, separator, std.mem.tokenizeSequence);
}

pub fn splitAnyA(alloc: std.mem.Allocator, s: []const u8, separator: []const u8) ![][]const u8 {
    return genSplitA(alloc, s, separator, std.mem.tokenizeAny);
}

test "splitA" {
    const toks = try splitA(std.testing.allocator, "A B C  D E  F", " ");
    defer std.testing.allocator.free(toks);
    for (toks, [_][]const u8{ "A", "B", "C", "D", "E", "F" }) |a, b| try testing.expectEqualSlices(u8, a, b);
}

pub fn toNum(comptime T: type, s: []const u8) !T {
    switch (T) {
        f32, f64 => return std.fmt.parseFloat(T, trim(s)),
        else => return std.fmt.parseInt(T, trim(s), 10),
    }
}

test "toInt" {
    try testing.expectEqual(toNum(i32, "42"), 42);
    try testing.expectEqual(toNum(i32, "  42  "), 42);
    try testing.expectError(error.InvalidCharacter, toNum(i32, "42,"));
}

test "toInt64" {
    try testing.expectEqual(toNum(i64, "42"), 42);
    try testing.expectEqual(toNum(i64, "  42  "), 42);
    try testing.expectError(error.InvalidCharacter, toNum(i64, "42,"));
}

test "toF32" {
    try testing.expectEqual(toNum(f32, "42.23"), 42.23);
    try testing.expectEqual(toNum(f32, "  -42.23  "), -42.23);
    try testing.expectError(error.InvalidCharacter, toNum(f32, "42,23"));
}

test "toF64" {
    try testing.expectEqual(toNum(f64, "42.23"), 42.23);
    try testing.expectEqual(toNum(f64, "  -42.23  "), -42.23);
    try testing.expectError(error.InvalidCharacter, toNum(f64, "42,23"));
}

fn genToMany(comptime T: type, comptime N: usize, s: []const u8, separator: []const u8, comptime tokenize: anytype) ![N]T {
    var result: [N]T = undefined;
    var toks = tokenize(u8, s, separator);
    var i: usize = 0;
    while (toks.next()) |tok| {
        if (i == N) return SplitErr.TooManyElementsForSplit;
        result[i] = try toNum(T, tok);
        i += 1;
    }
    if (i < N) return SplitErr.TooFewElementsForSplit;
    return result;
}

pub fn toNums(comptime T: type, comptime N: usize, s: []const u8, separator: []const u8) ![N]T {
    return genToMany(T, N, s, separator, std.mem.tokenizeSequence);
}

pub fn toNumsAny(comptime T: type, comptime N: usize, s: []const u8, separator: []const u8) ![N]T {
    return genToMany(T, N, s, separator, std.mem.tokenizeAny);
}

test "toInts" {
    try testing.expectEqual(toNums(u32, 6, "1, 2, 3,4,   5   ,6", ","), .{ 1, 2, 3, 4, 5, 6 });
    try testing.expectEqual(toNums(u32, 6, "1,,2,,3,4,,,,5,,,,6", ","), .{ 1, 2, 3, 4, 5, 6 });
    try testing.expectEqual(toNums(u32, 6, "1  2  3 4    5    6", " "), .{ 1, 2, 3, 4, 5, 6 });
    try testing.expectError(error.InvalidCharacter, toNums(u32, 6, "1, 2, a,4,   5   ,6", ","));
    try testing.expectError(error.InvalidCharacter, toNums(u32, 6, "1, 2, ,4,   5   ,6", ","));
    try testing.expectError(error.TooManyElementsForSplit, toNums(u32, 5, "1, 2, 3,4,   5   ,6", ","));
    try testing.expectError(error.TooFewElementsForSplit, toNums(u32, 7, "1, 2, 3,4,   5   ,6", ","));
}

fn genToManyA(comptime T: type, alloc: std.mem.Allocator, s: []const u8, separator: []const u8, comptime tokenize: anytype) ![]T {
    var result: std.ArrayList(T) = .empty;
    defer result.deinit(alloc);

    var toks = tokenize(u8, s, separator);
    while (toks.next()) |tok| try result.append(alloc, try toNum(T, tok));

    return result.toOwnedSlice(alloc);
}

pub fn toNumsA(comptime T: type, alloc: std.mem.Allocator, s: []const u8, separator: []const u8) ![]T {
    return genToManyA(T, alloc, s, separator, std.mem.tokenizeSequence);
}

pub fn toNumsAnyA(comptime T: type, alloc: std.mem.Allocator, s: []const u8, separator: []const u8) ![]T {
    return genToManyA(T, alloc, s, separator, std.mem.tokenizeAny);
}

test "toNumsA" {
    const a = testing.allocator_instance.allocator();
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const aa = arena.allocator();

    try testing.expectEqualSlices(u32, (try toNumsA(u32, aa, "1, 2, 3,4,   5   ,6", ",")), &[_]u32{ 1, 2, 3, 4, 5, 6 });
    try testing.expectEqualSlices(u32, (try toNumsA(u32, aa, "1,,2,,3,4,,,,5,,,,6", ",")), &[_]u32{ 1, 2, 3, 4, 5, 6 });
    try testing.expectEqualSlices(u32, (try toNumsA(u32, aa, "1  2  3 4    5    6", " ")), &[_]u32{ 1, 2, 3, 4, 5, 6 });
    try testing.expectError(error.InvalidCharacter, toNumsA(u32, a, "1, 2, a,4,   5   ,6", ","));
    try testing.expectError(error.InvalidCharacter, toNumsA(u32, a, "1, 2, ,4,   5   ,6", ","));
}

test "toNumsAnyA" {
    const a = testing.allocator_instance.allocator();
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const aa = arena.allocator();

    try testing.expectEqualSlices(u32, (try toNumsAnyA(u32, aa, "1, 2, 3,4,   5   ,6", ", ")), &[_]u32{ 1, 2, 3, 4, 5, 6 });
    try testing.expectEqualSlices(u32, (try toNumsAnyA(u32, aa, "1,,2,,3,4,,,,5,,,,6", ",")), &[_]u32{ 1, 2, 3, 4, 5, 6 });
    try testing.expectEqualSlices(u32, (try toNumsAnyA(u32, aa, "1  2  3 4    5    6", " ")), &[_]u32{ 1, 2, 3, 4, 5, 6 });
    try testing.expectError(error.InvalidCharacter, toNumsAnyA(u32, a, "1, 2, a,4,   5   ,6", ","));
    try testing.expectError(error.InvalidCharacter, toNumsAnyA(u32, a, "1, 2, ,4,   5   ,6", ","));
}

test "toFloats" {
    try testing.expectEqual(toNums(f32, 6, "1.42, 2.42, 3.42,4.42,   5.42   ,6.42", ","), .{ 1.42, 2.42, 3.42, 4.42, 5.42, 6.42 });
    try testing.expectEqual(toNums(f32, 6, "1.42,,2.42,,3.42,4.42,,,,5.42,,,,6.42", ","), .{ 1.42, 2.42, 3.42, 4.42, 5.42, 6.42 });
    try testing.expectEqual(toNums(f32, 6, "1.42  2.42  3.42 4.42    5.42    6.42", " "), .{ 1.42, 2.42, 3.42, 4.42, 5.42, 6.42 });
    try testing.expectError(error.InvalidCharacter, toNums(f32, 6, "1.42, 2.42, a,4.42,   5.42   ,6.42", ","));
    try testing.expectError(error.InvalidCharacter, toNums(f32, 6, "1.42, 2.42, ,4.42,   5.42   ,6.42", ","));
    try testing.expectError(error.TooManyElementsForSplit, toNums(f32, 5, "1.42, 2.42, 3.42,4.42,   5.42   ,6.42", ","));
    try testing.expectError(error.TooFewElementsForSplit, toNums(f32, 7, "1.42, 2.42, 3.42,4.42,   5.42   ,6.42", ","));
}

pub fn sort(comptime T: type, items: []T) void {
    std.mem.sortUnstable(T, items, {}, std.sort.asc(T));
}

/// least common multiple
pub fn lcm(a: u64, b: u64) u64 {
    return a * (b / std.math.gcd(a, b));
}

pub fn lcmOfAll(nums: []u64) u64 {
    var a = nums[0];
    for (nums[1..]) |b| a = lcm(a, b);
    return a;
}

/// Euclid's algorithm.
pub fn gcd(comptime T: type, a: T, b: T) T {
    var r0 = a;
    var r1 = b;
    while (r1 != 0) {
        const q = @divFloor(r0, r1);
        const r2 = @rem(r0, r1);
        if (r2 != r0 - q * r1) unreachable;

        r0 = r1;
        r1 = r2;
    }

    return r0;
}

/// Extended version of Euclid's algorithm.
///
/// Returns s and t such that s*a+t*b=gcd.
pub fn gcd_ext(comptime T: type, a: T, b: T) struct { gcd: T, s: T, t: T } {
    var r0 = a;
    var r1 = b;
    var s0: T = 1;
    var s1: T = 0;
    var t0: T = 0;
    var t1: T = 1;
    while (r1 != 0) {
        const q = @divFloor(r0, r1);
        const r2 = @rem(r0, r1);
        if (r2 != r0 - q * r1) unreachable;
        const s2 = s0 - q * s1;
        const t2 = t0 - q * t1;

        r0 = r1;
        r1 = r2;
        s0 = s1;
        s1 = s2;
        t0 = t1;
        t1 = t2;
    }

    if (s0 * a + t0 * b != r0) unreachable;

    return .{ .gcd = r0, .s = s0, .t = t0 };
}

pub fn Crt(comptime T: type) type {
    return struct { a: T, m: T };
}

pub fn crt(comptime T: type, eqs: []const Crt(T)) ?T {
    if (eqs.len == 0) return null;
    if (eqs.len == 1) return eqs[0].a;

    var a0: T = @intCast(eqs[0].a);
    var m0: T = @intCast(eqs[0].m);
    for (1..eqs.len) |i| {
        const a1: T = @intCast(eqs[i].a);
        const m1: T = @intCast(eqs[i].m);
        const g = gcd_ext(T, m0, m1);
        if (@rem(a0, g.gcd) != @rem(a1, g.gcd)) return null;
        const l = m0 * @divFloor(m1, g.gcd);
        if (@rem(m1, g.gcd) != 0) unreachable;
        const x = @rem(a0 - g.s * m0 * @divFloor(a0 - a1, g.gcd), l);
        a0 = x;
        m0 = l;
        // there should be a better way to ensure 0 <= a0 < m0
        while (a0 < 0) : (a0 += m0) {}
        while (a0 >= m0) : (a0 -= m0) {}
    }

    return @intCast(a0);
}

test "crt" {
    try std.testing.expectEqual(@as(?i64, 301), //
        crt(i64, &.{
            .{ .a = 1, .m = 2 },
            .{ .a = 1, .m = 3 },
            .{ .a = 1, .m = 4 },
            .{ .a = 1, .m = 5 },
            .{ .a = 1, .m = 6 },
            .{ .a = 0, .m = 7 },
        }));

    try std.testing.expectEqual(@as(?i64, 47), //
        crt(i64, &.{
            .{ .a = 2, .m = 3 },
            .{ .a = 3, .m = 4 },
            .{ .a = 2, .m = 5 },
        }));

    try std.testing.expectEqual(@as(?i64, 23), //
        crt(i64, &.{
            .{ .a = 2, .m = 3 },
            .{ .a = 3, .m = 5 },
            .{ .a = 2, .m = 7 },
        }));
}

test {
    testing.refAllDecls(@This());
}

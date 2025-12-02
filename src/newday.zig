// Copyright (c) 2025 Frank Fischer <frank-fischer@shadow-soft.de>
//
// This program is free software: you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see  <http://www.gnu.org/licenses/>

const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Io = std.Io;

const YEAR: u32 = 2025;

pub fn main() !void {
    var allocator: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const gpa = allocator.allocator();

    var threaded: Io.Threaded = .init(gpa);
    defer threaded.deinit();
    const io = threaded.io();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len < 2) {
        std.debug.print("Usage: newday DAY\n", .{});
        return;
    }

    const day = try std.fmt.parseInt(u32, args[1], 10);

    if (day < 1 or day > 25) return error.DayOutOfBounds;

    try downloadInput(gpa, io, day);
    try createMainFromTemplate(io, day);
}

fn downloadInput(gpa: Allocator, io: Io, day: u32) !void {
    // read session cookie
    var session_buf: [256]u8 = undefined;
    const key_len = (try std.fmt.bufPrint(&session_buf, "session=", .{})).len;
    const session_key = Io.Dir.cwd().readFile(io, ".session", session_buf[key_len..]) catch |err| {
        std.log.err("Error reading session-cookie from `.session`", .{});
        return err;
    };
    const session_len = std.mem.trim(u8, session_key, "\r\n \t").len;
    const session = session_buf[0 .. key_len + session_len];

    var http_client: std.http.Client = .{ .allocator = gpa, .io = io };
    defer http_client.deinit();

    var tmp_writer = Io.Writer.Allocating.init(gpa);
    defer tmp_writer.deinit();

    var buffer: [4096]u8 = undefined;
    var result = try http_client.fetch(
        .{
            .location = .{ .url = try std.fmt.bufPrint(&buffer, "https://adventofcode.com/{}/day/{}/input", .{ YEAR, day }) },
            .extra_headers = &[_]std.http.Header{.{ .name = "Cookie", .value = session }},
            .response_writer = &tmp_writer.writer,
        },
    );
    if (result.status != .ok) {
        std.log.err("Request failed ({}): {s}", .{ result.status, tmp_writer.written() });
        return error.DownloadFailed;
    }

    // create input/XX/input1.txt
    try Io.Dir.cwd().makePath(io, try std.fmt.bufPrint(&buffer, "input/{:02}", .{day}));
    const filename = try std.fmt.bufPrint(&buffer, "input/{:02}/input1.txt", .{day});
    var file = try std.fs.cwd().createFile(filename, .{ .truncate = true });
    defer file.close();

    std.log.info("Downloaded input file to {s}", .{filename});

    // save downloaded file
    var file_writer = file.writer(&buffer);
    defer file_writer.interface.flush() catch {};
    var reader = Io.Reader.fixed(tmp_writer.written());
    _ = try reader.streamRemaining(&file_writer.interface);
}

fn createMainFromTemplate(io: Io, day: u32) !void {
    var buffer: [4096]u8 = undefined;
    const cwd = Io.Dir.cwd();

    // create a new template
    try cwd.makePath(io, try std.fmt.bufPrint(&buffer, "src/{:02}", .{day}));

    // hopefully the template is not larger than 4k
    const content = try cwd.readFile(io, "src/template_main.zig", &buffer);

    var day_buf: [2]u8 = undefined;
    const day_str = try std.fmt.bufPrint(&day_buf, "{}", .{day});

    var replaced_buffer: [4096]u8 = undefined;
    const n = std.mem.replace(u8, content, "DAY", day_str, &replaced_buffer);
    const replaced_content = replaced_buffer[0 .. content.len - n * (3 - day_str.len)];

    const filename = try std.fmt.bufPrint(&buffer, "src/{:02}/main.zig", .{day});
    // TODO: currently there is compile error if using std.Io.Dir.cwd().writeFile
    std.fs.cwd().writeFile(.{
        .sub_path = filename,
        .flags = .{ .truncate = false, .exclusive = true },
        .data = replaced_content,
    }) catch |err| {
        switch (err) {
            error.PathAlreadyExists => std.log.warn("Not replacing existing {s}", .{filename}),
            else => return err,
        }
        return;
    };

    std.log.info("Created {s}", .{filename});
}

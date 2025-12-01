const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const mod_newday_exe = b.addModule("newday", .{
        .root_source_file = b.path("src/newday.zig"),
        .target = target,
        .optimize = optimize,
    });
    const newday_exe = b.addExecutable(.{ .name = "newday", .root_module = mod_newday_exe });

    const newday_inst = b.addInstallArtifact(newday_exe, .{});
    b.getInstallStep().dependOn(&newday_inst.step);
    const newday_cmd = b.addRunArtifact(newday_exe);
    newday_cmd.step.dependOn(&newday_inst.step);
    const newday_step = b.step("newday", "Prepare everything for a new day");
    newday_step.dependOn(&newday_cmd.step);

    const aoc = b.createModule(.{ .root_source_file = b.path("src/aoc.zig") });

    const mod_unit_tests = b.addModule("test_aoc", .{
        .root_source_file = b.path("src/aoc.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lib_unit_tests = b.addTest(.{ .root_module = mod_unit_tests });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    var gen_txt: [1024 * 100]u8 = undefined;
    var gen_w = std.Io.Writer.fixed(&gen_txt);
    const gen_step = b.addWriteFiles();

    try gen_w.writeAll(
        \\const std = @import("std");
        \\const aoc = @import("aoc");
        \\
    );

    // collect all main source files for all days and versions
    const Main = struct {
        day: u8,
        version: []u8,
        name: []u8,
        mod_name: []u8 = &[_]u8{},
        module: *std.Build.Module = undefined,

        fn less(_: void, main_a: @This(), main_b: @This()) bool {
            if (main_a.day != main_b.day) return main_a.day < main_b.day;
            switch (std.mem.order(u8, main_a.name, main_b.name)) {
                .lt => return true,
                .gt => return false,
                else => return std.mem.lessThan(u8, main_a.name, main_b.name),
            }
        }
    };
    var mains: std.ArrayList(Main) = .empty;
    defer mains.deinit(b.allocator);

    var dir = try std.fs.openDirAbsolute(b.pathFromRoot("src"), .{ .iterate = true });
    defer dir.close();
    var dir_it = dir.iterate();
    while (try dir_it.next()) |d| {
        if (d.kind != .directory or d.name.len > 2) continue;
        const day = std.fmt.parseInt(u8, d.name, 10) catch continue;
        if (day < 0 or day > 25) continue;

        var day_dir = try dir.openDir(d.name, .{ .iterate = true });
        defer day_dir.close();
        var day_it = day_dir.iterate();
        while (try day_it.next()) |main| {
            if (main.kind != .file) continue;
            if (!std.mem.startsWith(u8, main.name, "main")) continue;
            if (!std.mem.endsWith(u8, main.name, ".zig")) continue;

            const version = b.dupe(std.mem.trim(u8, main.name[4 .. main.name.len - 4], "_"));

            try mains.append(b.allocator, .{ .day = day, .version = version, .name = b.dupe(main.name) });
        }
    }

    // sort the main files by day and version
    std.mem.sortUnstable(Main, mains.items, {}, Main.less);

    try gen_w.writeAll("const days = .{\n");
    for (mains.items) |*main| {
        const exe_name = if (main.version.len == 0)
            try std.fmt.allocPrint(b.allocator, "{d:0>2}", .{main.day})
        else
            try std.fmt.allocPrint(b.allocator, "{d:0>2}_{s}", .{ main.day, main.version });
        const exe_src = try std.fmt.allocPrint(b.allocator, "src/{d:0>2}/{s}", .{ main.day, main.name });

        const mod_exe = b.addModule("exe", .{
            .root_source_file = b.path(exe_src),
            .target = target,
            .optimize = optimize,
        });
        const exe = b.addExecutable(.{ .name = exe_name, .root_module = mod_exe });
        exe.root_module.strip = optimize == .ReleaseFast or optimize == .ReleaseSmall;
        exe.root_module.addImport("aoc", aoc);

        // make a module for this day
        const exe_mod = b.createModule(.{ .root_source_file = b.path(exe_src) });
        exe_mod.addImport("aoc", aoc);
        main.mod_name = exe_name;
        main.module = exe_mod;

        // install step
        const inst = b.addInstallArtifact(exe, .{});
        b.getInstallStep().dependOn(&inst.step); // add to global install step

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&inst.step); // run depends on install

        // This allows the user to pass arguments to the application in the build
        // command itself, like this: `zig build run -- arg1 arg2 etc`
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        // user visible step
        const run_step_name = if (main.version.len == 0)
            try std.fmt.allocPrint(b.allocator, "run{d:0>2}", .{main.day})
        else
            try std.fmt.allocPrint(b.allocator, "run{d:0>2}_{s}", .{ main.day, main.version });

        const run_step_desc = if (main.version.len == 0)
            try std.fmt.allocPrint(b.allocator, "Run day {d:0>2}", .{main.day})
        else
            try std.fmt.allocPrint(b.allocator, "Run day {d:0>2} v{s}", .{ main.day, main.version });

        const run_step = b.step(run_step_name, run_step_desc);
        run_step.dependOn(&run_cmd.step);

        // tests
        const mod_exe_unit_tests = b.addModule("exe_unit_tests", .{
            .root_source_file = b.path(exe_src),
            .target = target,
            .optimize = optimize,
        });
        const exe_unit_tests = b.addTest(.{ .name = exe_name, .root_module = mod_exe_unit_tests });
        exe_unit_tests.root_module.addImport("aoc", aoc);
        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
        test_step.dependOn(&run_exe_unit_tests.step);

        // add to list of modules
        if (main.version.len == 0)
            try gen_w.print("    .{{ .day = {0d}, .version = \"\", .filename = \"input/{0d:0>2}/input1.txt\", .run = @import(\"{0d:0>2}\").run }},\n", .{main.day})
        else
            try gen_w.print("    .{{ .day = {0d}, .version = \"{1s}\", .filename = \"input/{0d:0>2}/input1.txt\", .run = @import(\"{0d:0>2}_{1s}\").run }},\n", .{ main.day, main.version });
    }

    try gen_w.print("}};\n\n", .{});
    try gen_w.writeAll(
        \\pub fn main() !void {
        \\    var args = std.process.args();
        \\    const program = args.next() orelse return error.MissingFilename; // skip the program name
        \\    while (args.next()) |arg| {
        \\        if (std.mem.eql(u8, arg, "--json") or std.mem.eql(u8, arg, "-j")) {
        \\            return try aoc.run_times_json(days);
        \\        }
        \\        else {
        \\            return std.debug.print("Usage: {s} [-j|--json]\n", .{ std.fs.path.basename(program) });
        \\        }
        \\    }
        \\    try aoc.run_times(days);
        \\}
    );

    const times_path = gen_step.add("times.zig", gen_w.buffered());
    const mod_times_exe = b.addModule("times", .{
        .root_source_file = times_path,
        .target = target,
        .optimize = optimize,
    });
    const times_exe = b.addExecutable(.{ .name = "times", .root_module = mod_times_exe });
    times_exe.root_module.strip = optimize == .ReleaseFast or optimize == .ReleaseSmall;
    for (mains.items) |main| times_exe.root_module.addImport(main.mod_name, main.module);
    times_exe.step.dependOn(&gen_step.step);
    times_exe.root_module.addImport("aoc", aoc);
    const times_inst = b.addInstallArtifact(times_exe, .{});
    b.getInstallStep().dependOn(&times_inst.step);

    const times_cmd = b.addRunArtifact(times_exe);
    times_cmd.step.dependOn(&times_inst.step);
    const times_step = b.step("times", "Run all exercises with timings");
    times_step.dependOn(&times_cmd.step);

    const times_json_cmd = b.addRunArtifact(times_exe);
    times_json_cmd.addArg("--json");
    times_json_cmd.step.dependOn(&times_inst.step);
    const times_json_step = b.step("times-json", "Run all exercises with timings and output json format");
    times_json_step.dependOn(&times_json_cmd.step);
}

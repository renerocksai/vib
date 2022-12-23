const std = @import("std");
const argsParser = @import("args.zig");
const version_string = @import("version.zig").version_string;

const MAX_FILE_SIZE = 32 * 1024 * 1024;

fn print_help(exe_name: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("vib version {s}\n", .{version_string});
    try stdout.print("Usage: {s} [options]\n", .{exe_name});
    try stdout.writeAll(
        \\
        \\Reads all of stdin until EOF, dumps it into a temporary file, and
        \\launches a browser.
        \\
        \\Options are:
        \\  -e, --exec     : optional name of the executable (browser) to launch
        \\  -p, --prefix   : optional prefix for temp file names. Default: vib-
        \\  -t, --tmpdir   : temp dir to write to. Default: /tmp
        \\  -o, --output   : optional path to write to instead of temp file
        \\  -c, --cleanup  : delete all of vib's temp files before creating a new one
        \\
        \\Examples:
        \\vib -e sensible-browser
        \\  Launch the sensible-browser, use defaults for all options.
        \\
        \\vib -e firefox -c -t /tmp/vib-messages
        \\  Delete vib's temp files from previous runs, then create a new one
        \\  and launch firefox with the piped-in message.
        \\
        \\vib -o /tmp/current-message.html
        \\  Launch no browser, just write to /tmp/current-message.html
        \\  This allows you to leave the browser open on the same page,
        \\  while using vib to refresh the content.
        \\
    );
}

/// work out filename based on options
fn makeTempFileName(
    a: std.mem.Allocator,
    fname: ?[]const u8,
    tmpdir: []const u8,
    prefix: []const u8,
) ![]const u8 {
    if (fname) |present| return present;

    const itime = std.time.milliTimestamp();
    const filename = try std.fmt.allocPrint(
        a,
        "{s}/{s}{d}.html",
        .{ tmpdir, prefix, itime },
    );
    return filename;
}

/// Writes contents to temp file
fn writeToFile(fname: []const u8, contents: []const u8) !void {
    var file = try std.fs.cwd().createFile(fname, .{});
    defer file.close();
    try file.writer().writeAll(contents);
}

/// Writes contents to temp file
fn writeStdinToFile(
    fname: []const u8,
) !void {
    // output file
    var ofile = try std.fs.cwd().createFile(fname, .{});
    defer ofile.close();
    var bw = std.io.bufferedWriter(ofile.writer());
    var w = bw.writer();

    // input stream
    var ifile = std.io.getStdIn();
    var br = std.io.bufferedReader(ifile.reader());
    var r = br.reader();

    // read buffer
    var buffer: [1024 * 4096]u8 = undefined;

    var bytesRead: usize = 1; // to enter the loop
    while (bytesRead != 0) {
        bytesRead = try r.read(&buffer);
        if (bytesRead > 0) {
            try w.writeAll(buffer[0..bytesRead]);
        }
    }
    try bw.flush();
}

/// Launches browser with args
fn launchBrowser(
    alloc: std.mem.Allocator,
    browser: []const u8,
    url: []const u8,
) !void {
    const args = [_][]const u8{
        browser,
        url,
    };

    if (std.ChildProcess.exec(.{ .argv = args[0..], .allocator = alloc })) |_| {
        return;
    } else |err| {
        std.log.err("Unable to spawn and wait:  {any}", .{err});
    }
}

/// Cleans vib files from tmpdir
fn cleanup(tmpdir: []const u8, prefix: []const u8) !void {
    const d = try std.fs.cwd().openIterableDir(tmpdir, .{ .access_sub_paths = true });
    var it = d.iterate();
    while (try it.next()) |f| {
        if (f.kind == .File and std.mem.startsWith(u8, f.name, prefix)) {
            try d.dir.deleteFile(f.name);
        }
    }
}

pub fn main() anyerror!void {
    const alloc = std.heap.page_allocator;
    if (argsParser.parseForCurrentProcess(struct {
        // This declares long options for double hyphen
        output: ?[]const u8 = null,
        tmpdir: []const u8 = "/tmp",
        prefix: []const u8 = "vib-",
        exec: ?[]const u8 = null,
        cleanup: bool = false,
        help: bool = false,

        // This declares short-hand options for single hyphen
        pub const shorthands = .{
            .e = "exec",
            .p = "prefix",
            .t = "tmpdir",
            .o = "output",
            .c = "cleanup",
        };
    }, alloc, .print)) |options| {
        defer options.deinit();

        const o = options.options;

        // check options for invoking help
        if (o.help or
            (o.output == null and o.exec == null and o.cleanup == false))
        {
            try print_help(options.executable_name orelse "vib");
            return;
        }

        // work out the temp filename
        const output_fn = try makeTempFileName(
            alloc,
            o.output,
            o.tmpdir,
            o.prefix,
        );

        // check if we need to clean up
        if (o.output == null and o.cleanup) {
            try cleanup(o.tmpdir, o.prefix);
        }

        // write html into temp file
        try writeStdinToFile(output_fn);

        // launch browser
        if (o.exec) |browser| {
            try launchBrowser(alloc, browser, output_fn);
        }
    } else |err| {
        std.debug.print("{!}", .{err});
        try print_help("vib");
    }
}

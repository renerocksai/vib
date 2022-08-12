const std = @import("std");
const argsParser = @import("args.zig");
const version_string = @import("version.zig").version_string;

const MAX_FILE_SIZE = 10 * 1024 * 1024;

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
        \\  -e, --exec     : name of the executable (browser) to launch.
        \\  -s, --max-size : max size of memory for input in bytes. Default: 10MB
        \\  -p, --prefix   : optional prefix for temp file names. Default: vib-
        \\  -t, --tmpdir   : temp dir to write to. Default: /tmp
        \\  -o, --output   : optional path to write to instead of temp file
        \\
        \\Examples:
        \\vib -e sensible-browser
        \\
        \\vib -e sensible-browser -t /tmp/vib-messages
        \\
        \\vib -o /tmp/current-message.html
        \\  Launch no browser, just write to /tmp/current-message.html
        \\  This allows you to leave the browser open on the same page,
        \\  while using vib
        \\
    );
}

/// reads entire stdin, allocating via alloc a buffer of max size max_size.
/// returns the buffer
fn readStdin(alloc: std.mem.Allocator, max_size: usize) ![]const u8 {
    const stdin = std.io.getStdIn().reader();

    return stdin.readAllAlloc(alloc, max_size);
}

/// work out filename based on options
fn makeTempFileName(a: std.mem.Allocator, fname: ?[]const u8, tmpdir: []const u8, prefix: []const u8) ![]const u8 {
    if (fname) |present| return present;

    const itime = std.time.milliTimestamp();
    const filename = try std.fmt.allocPrint(a, "{s}/{s}{d}.html", .{ tmpdir, prefix, itime });
    return filename;
}

/// Writes contents to temp file
fn writeToFile(fname: []const u8, contents: []const u8) !void {
    //
    var file = try std.fs.cwd().createFile(fname, .{});
    defer file.close();
    try file.writer().writeAll(contents);
}

/// Launches browser with args
fn launchBrowser(alloc: std.mem.Allocator, browser: []const u8, url: []const u8) !void {
    const args = [_][]const u8{
        browser,
        url,
    };

    if (std.ChildProcess.exec(.{ .argv = args[0..], .allocator = alloc })) |ret| {
        _ = ret;
        return;
    } else |err| {
        std.log.err("Unable to spawn and wait:  {any}", .{err});
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
        @"max-size": u32 = MAX_FILE_SIZE,
        help: bool = false,

        // This declares short-hand options for single hyphen
        pub const shorthands = .{
            .e = "exec",
            .s = "max-size",
            .p = "prefix",
            .t = "tmpdir",
            .o = "output",
        };
    }, alloc, .print)) |options| {
        defer options.deinit();

        const o = options.options;

        // check options for --help
        if (o.help or (o.output == null and o.exec == null)) {
            try print_help(options.executable_name orelse "vib");
            return;
        }

        // read html from stdin
        const html = try readStdin(alloc, MAX_FILE_SIZE);
        _ = html;

        // work out the temp filename
        const output_fn = try makeTempFileName(alloc, o.output, o.tmpdir, o.prefix);

        // write html into temp file
        try writeToFile(output_fn, html);

        // launch browser
        if (o.exec) |browser| {
            try launchBrowser(alloc, browser, output_fn);
        }
    } else |err| {
        std.debug.print("{s}", .{err});
        try print_help("vib");
    }
}

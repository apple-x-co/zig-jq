const std = @import("std");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.nextPosix().?; // skip program name

    const stdout = std.io.getStdOut();
    const stderr = std.io.getStdErr();
    
    var arg = args.nextPosix();
    if (arg == null) {
        const stdin = std.io.getStdIn();
        jq(stdin, stdout, stderr, allocator) catch |err| {
            std.log.warn("error reading stdin : {}", .{err});
        };

        return;
    }

    while (true) : (arg = args.nextPosix()) {
        if (arg == null) {
            break;
        }

        const file = try std.fs.cwd().openFile(arg.?, .{ .read = true, .write = false });
        defer file.close();
        jq(file, stdout, stderr, allocator) catch |err| {
            std.log.warn("error reading file '{s}': {}", .{ arg.?, err });
        };
    }
}

fn jq(in: std.fs.File, out: std.fs.File, errOut: std.fs.File, allocator: std.mem.Allocator) anyerror!void {
    const reader = in.reader();
    const writer = out.writer();
    const errWriter = errOut.writer();

    var parser = std.json.Parser.init(allocator, false);
    defer parser.deinit();
    
    var payload = try reader.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(payload);

    var parsed = parser.parse(payload) catch |err| {
        try errWriter.print("error: {s}\n", .{@errorName(err)});

        return;
    };
    defer parsed.deinit();

    try parsed.root.jsonStringify(std.json.StringifyOptions{
        .whitespace = std.json.StringifyOptions.Whitespace{}
    }, writer);
    try writer.print("\n", .{});
}
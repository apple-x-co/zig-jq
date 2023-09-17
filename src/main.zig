const std = @import("std");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next().?; // skip program name

    const stdout = std.io.getStdOut();
    const stderr = std.io.getStdErr();

    var arg = args.next();
    if (arg == null) {
        const stdin = std.io.getStdIn();
        jq(stdin, stdout, stderr, allocator) catch |err| {
            std.log.warn("error reading stdin : {}", .{err});
        };

        return;
    }

    while (true) : (arg = args.next()) {
        if (arg == null) {
            break;
        }

        const file = try std.fs.cwd().openFile(arg.?, .{ .mode = .read_only });
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
    _ = errWriter;

    var payload = try reader.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(payload);

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, payload, .{});
    defer parsed.deinit();
    const root = parsed.value;

    const writer_stream = std.json.writeStream(writer, .{});
    _ = writer_stream;

    root.dump();
    try writer.print("\n", .{});
}

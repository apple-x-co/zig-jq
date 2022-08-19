const std = @import("std");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.nextPosix().?; // skip program name

    const stdout = std.io.getStdOut();
    
    var arg = args.nextPosix();
    if (arg == null) {
        const stdin = std.io.getStdIn();
        jq(stdin, stdout, allocator) catch |err| {
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
        jq(file, stdout, allocator) catch |err| {
            std.log.warn("error reading file '{s}': {}", .{ arg.?, err });
        };
    }
}

fn jq(in: std.fs.File, out: std.fs.File, allocator: std.mem.Allocator) anyerror!void {
    _ = in.reader();
    const writer = out.writer();

    var parser = std.json.Parser.init(allocator, false);
    defer parser.deinit();
    
    const payload =
        \\{
        \\    "vals": {
        \\        "testing": 1,
        \\        "production": 42
        \\    },
        \\    "uptime": 9999
        \\}
    ;
    var parsed = parser.parse(payload) catch |err| {
        std.debug.print("error: {s}", .{@errorName(err)});
        return;
    };
    defer parsed.deinit();

    //std.debug.print("{s}\n", .{parsed.root.dump()});

    try parsed.root.jsonStringify(std.json.StringifyOptions{
        .whitespace = std.json.StringifyOptions.Whitespace{}
    }, writer);
    std.debug.print("\n", .{});

    // const reader = in.reader();
    // const writer = out.writer();

    // var buf: [std.mem.page_size]u8 = undefined;
    // var i: u32 = 1;
    // while (true) : (i += 1) {
    //     var line = reader.readUntilDelimiterOrEof(buf[0..buf.len], '\n') catch null;
    //     if (line == null) {
    //         break;
    //     }

    //     if (try regex.partialMatch(line.?)) {
    //         try writer.print("{}:{s}\n", .{ i, line.? });
    //     }
    // } else |err| {
    //     std.log.warn("{}", .{err});
    // }
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}

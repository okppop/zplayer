const Channel = @import("channel.zig");
const std = @import("std");
const t = std.testing;

test "hello" {
    const size: u8 = 10;
    var ch = try Channel.Channel(u8).init(t.allocator, size);
    defer ch.deinit(t.allocator);

    for (0..10) |i| {
        std.debug.print("{d}\n", .{i});
        try ch.push(@intCast(i));
    }

    // var i: u8 = size - 2;
    // while (i != -1) {
    //     try t.expect(try ch.pop() == i);
    //     i -= 1;
    // }
}

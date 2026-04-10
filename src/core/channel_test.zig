const std = @import("std");
const t = std.testing;
const Channel = @import("channel.zig");
const RingBuffer = @import("ring_buffer.zig");

test "Channel - sequential push and pop" {
    const size: u8 = 10;
    var ch = try Channel.Channel(u8).init(t.allocator, size);
    defer ch.deinit(t.allocator);

    for (0..10) |i| {
        try ch.push(@intCast(i));
    }

    for (0..10) |i| {
        try t.expect(try ch.pop() == i);
    }
}

test "Channel - single element capacity" {
    var ch = try Channel.Channel(u32).init(t.allocator, 1);
    defer ch.deinit(t.allocator);

    try ch.push(42);
    try t.expectEqual(@as(u32, 42), try ch.pop());

    try ch.push(99);
    try t.expectEqual(@as(u32, 99), try ch.pop());
}

test "Channel - fill drain multiple cycles" {
    var ch = try Channel.Channel(u16).init(t.allocator, 4);
    defer ch.deinit(t.allocator);

    for (0..3) |cycle| {
        for (0..4) |i| {
            try ch.push(@intCast(cycle * 4 + i));
        }
        for (0..4) |i| {
            try t.expectEqual(@as(u16, @intCast(cycle * 4 + i)), try ch.pop());
        }
    }
}

test "Channel - interleaved push and pop" {
    var ch = try Channel.Channel(u8).init(t.allocator, 4);
    defer ch.deinit(t.allocator);

    try ch.push(1);
    try ch.push(2);
    try t.expectEqual(@as(u8, 1), try ch.pop());

    try ch.push(3);
    try t.expectEqual(@as(u8, 2), try ch.pop());
    try t.expectEqual(@as(u8, 3), try ch.pop());
}

test "Channel - struct type" {
    const Msg = struct {
        id: u32,
        value: i64,
    };

    var ch = try Channel.Channel(Msg).init(t.allocator, 4);
    defer ch.deinit(t.allocator);

    try ch.push(.{ .id = 1, .value = -100 });
    try ch.push(.{ .id = 2, .value = 200 });

    const m1 = try ch.pop();
    try t.expectEqual(@as(u32, 1), m1.id);
    try t.expectEqual(@as(i64, -100), m1.value);

    const m2 = try ch.pop();
    try t.expectEqual(@as(u32, 2), m2.id);
    try t.expectEqual(@as(i64, 200), m2.value);
}

test "Channel - producer consumer threads" {
    const n: u32 = 1000;
    var ch = try Channel.Channel(u32).init(t.allocator, 8);
    defer ch.deinit(t.allocator);

    var sum: u64 = 0;

    const producer = struct {
        fn run(c: *Channel.Channel(u32), count: u32) void {
            for (0..count) |i| {
                c.push(@intCast(i)) catch return;
            }
        }
    }.run;

    const consumer = struct {
        fn run(c: *Channel.Channel(u32), count: u32, result: *u64) void {
            for (0..count) |_| {
                const v = c.pop() catch return;
                result.* += v;
            }
        }
    }.run;

    const t1 = try std.Thread.spawn(.{}, producer, .{ ch, n });
    const t2 = try std.Thread.spawn(.{}, consumer, .{ ch, n, &sum });

    t1.join();
    t2.join();

    const expected: u64 = @as(u64, n) * (n - 1) / 2;
    try t.expectEqual(expected, sum);
}

test "Channel - multiple producers single consumer" {
    const items_per_producer: u32 = 500;
    const num_producers: u32 = 4;
    const total = items_per_producer * num_producers;

    var ch = try Channel.Channel(u32).init(t.allocator, 16);
    defer ch.deinit(t.allocator);

    const producer = struct {
        fn run(c: *Channel.Channel(u32), count: u32) void {
            for (0..count) |i| {
                c.push(@intCast(i)) catch return;
            }
        }
    }.run;

    var threads: [num_producers]std.Thread = undefined;
    for (0..num_producers) |i| {
        threads[i] = try std.Thread.spawn(.{}, producer, .{ ch, items_per_producer });
    }

    var received: u32 = 0;
    for (0..total) |_| {
        _ = try ch.pop();
        received += 1;
    }

    for (threads) |thr| {
        thr.join();
    }

    try t.expectEqual(total, received);
}

test "Channel - single producer multiple consumers" {
    const total: u32 = 2000;
    const num_consumers: u32 = 4;

    var ch = try Channel.Channel(u32).init(t.allocator, 16);
    defer ch.deinit(t.allocator);

    var sums: [num_consumers]u64 = .{0} ** num_consumers;

    const consumer = struct {
        fn run(c: *Channel.Channel(u32), count: u32, result: *u64) void {
            for (0..count) |_| {
                const v = c.pop() catch return;
                result.* += v;
            }
        }
    }.run;

    var threads: [num_consumers]std.Thread = undefined;
    for (0..num_consumers) |i| {
        threads[i] = try std.Thread.spawn(.{}, consumer, .{ ch, total / num_consumers, &sums[i] });
    }

    for (0..total) |i| {
        try ch.push(@intCast(i));
    }

    var total_sum: u64 = 0;
    for (threads) |thr| {
        thr.join();
    }
    for (sums) |s| {
        total_sum += s;
    }

    const expected: u64 = @as(u64, total) * (total - 1) / 2;
    try t.expectEqual(expected, total_sum);
}

test "Channel - close unblocks waiting pop" {
    var ch = try Channel.Channel(u8).init(t.allocator, 4);
    defer ch.deinit(t.allocator);

    var got_error = false;

    const waiter = struct {
        fn run(c: *Channel.Channel(u8), err_flag: *bool) void {
            // This will block because channel is empty, until close wakes it
            const result = c.pop();
            if (result) |_| {} else |_| {
                err_flag.* = true;
            }
        }
    }.run;

    const thr = try std.Thread.spawn(.{}, waiter, .{ ch, &got_error });

    // Give the thread time to start waiting
    std.Thread.sleep(10 * std.time.ns_per_ms);

    ch.close();
    // Broadcast to wake up the waiter
    ch.not_empty.broadcast();

    thr.join();

    try t.expect(got_error);
}

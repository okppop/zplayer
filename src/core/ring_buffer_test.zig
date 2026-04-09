const std = @import("std");
const t = std.testing;
const RingBuffer = @import("ring_buffer.zig").RingBuffer;
const RingBufferError = @import("ring_buffer.zig").RingBufferError;

test "empty on init" {
    var rb = try RingBuffer(u8).init(t.allocator, 4);
    defer rb.deinit(t.allocator);

    try t.expect(rb.is_empty());
    try t.expect(!rb.is_full());
}

test "push and pop" {
    var rb = try RingBuffer(u8).init(t.allocator, 4);
    defer rb.deinit(t.allocator);

    try rb.push(1);
    try rb.push(2);
    try rb.push(3);

    try t.expect(!rb.is_empty());
    try t.expect(!rb.is_full());

    try t.expectEqual(@as(u8, 1), try rb.pop());
    try t.expectEqual(@as(u8, 2), try rb.pop());
    try t.expectEqual(@as(u8, 3), try rb.pop());
    try t.expect(rb.is_empty());
}

test "full buffer" {
    var rb = try RingBuffer(u8).init(t.allocator, 3);
    defer rb.deinit(t.allocator);

    try rb.push(10);
    try rb.push(20);
    try rb.push(30);

    try t.expect(rb.is_full());
    try t.expectError(RingBufferError.BufferFull, rb.push(40));
}

test "pop from empty buffer" {
    var rb = try RingBuffer(u8).init(t.allocator, 3);
    defer rb.deinit(t.allocator);

    try t.expectError(RingBufferError.BufferEmpty, rb.pop());
}

test "wraparound" {
    var rb = try RingBuffer(u8).init(t.allocator, 3);
    defer rb.deinit(t.allocator);

    try rb.push(1);
    try rb.push(2);
    try rb.push(3);
    try t.expectEqual(@as(u8, 1), try rb.pop());

    try rb.push(4);
    try t.expect(rb.is_full());

    try t.expectEqual(@as(u8, 2), try rb.pop());
    try t.expectEqual(@as(u8, 3), try rb.pop());
    try t.expectEqual(@as(u8, 4), try rb.pop());
    try t.expect(rb.is_empty());
}

test "reset" {
    var rb = try RingBuffer(u8).init(t.allocator, 3);
    defer rb.deinit(t.allocator);

    try rb.push(1);
    try rb.push(2);
    try rb.reset();

    try t.expect(rb.is_empty());
    try t.expect(!rb.is_full());

    try rb.push(5);
    try t.expectEqual(@as(u8, 5), try rb.pop());
}

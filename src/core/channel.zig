const std = @import("std");
const Allocator = std.mem.Allocator;
const RingBuffer = @import("ring_buffer.zig").RingBuffer;
const RingBufferError = @import("ring_buffer.zig").RingBufferError;

pub const ChannelError = error{
    ChannelClosed,
};

/// Channel is a concurrency safe queue implementation.
pub fn Channel(comptime T: type) type {
    return struct {
        const Queue = RingBuffer(T);
        const Self = @This();

        queue: *Queue,
        mu: std.Thread.Mutex = .{},
        not_empty: std.Thread.Condition = .{},
        not_full: std.Thread.Condition = .{},
        is_closed: bool = false,

        pub fn init(allocator: Allocator, length: usize) !*Self {
            const self = try allocator.create(Self);
            self.* = .{
                .queue = try Queue.init(allocator, length),
            };
            return self;
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            self.queue.deinit(allocator);
            allocator.destroy(self);
        }

        pub fn push(self: *Self, item: T) ChannelError!void {
            self.mu.lock();
            defer self.mu.unlock();
            while (self.queue.is_full()) {
                self.not_full.wait(&self.mu);
                if (self.is_closed) return ChannelError.ChannelClosed;
            }

            self.queue.push(item) catch unreachable;
            self.not_empty.signal();
        }

        pub fn pop(self: *Self) ChannelError!T {
            self.mu.lock();
            defer self.mu.unlock();
            while (self.queue.is_empty()) {
                self.not_empty.wait(&self.mu);
                if (self.is_closed) return ChannelError.ChannelClosed;
            }

            const item = self.queue.pop() catch unreachable;
            self.not_full.signal();
            return item;
        }

        pub fn close(self: *Self) void {
            self.mu.lock();
            defer self.mu.unlock();
            self.is_closed = true;
        }
    };
}

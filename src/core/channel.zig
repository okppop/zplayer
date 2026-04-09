const std = @import("std");
const Allocator = std.mem.Allocator;
const RingBuffer = @import("ring_buffer.zig").RingBuffer;

pub fn Channel(comptime T: type) type {
    return struct {
        const Queue = RingBuffer(T);
        const Self = @This();

        queue: Queue,
        mu: std.Thread.Mutex = .{},
        not_empty: std.Thread.Condition = .{},
        not_full: std.Thread.Condition = .{},

        pub fn init(allocator: Allocator, length: usize) !*Self {
            const self = try allocator.create(Self);
            self.* = .{
                .rb = Queue.init(allocator, length),
            };
            return self;
        }

        pub fn deinit(self: *Self, allocator: Allocator) !void {
            try self.rb.deinit(allocator);
            try allocator.destroy(self);
        }

        pub fn push(self: *Self, item: T) !void {
            self.mu.lock();
            defer self.mu.unlock();

            while (self.queue.is_full()) self.not_full.wait(&self.mu);
            return self.push(item);
        }

        pub fn pop(self: *Self) !T {
            self.mu.lock();
            defer self.mu.unlock();

            while (self.queue.is_empty()) self.not_empty.wait(&self.mu);
            return self.pop();
        }
    };
}

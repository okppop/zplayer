const std = @import("std");
const Allocator = std.mem.Allocator;

pub const RingBufferError = error{
    BufferEmpty,
    BufferFull,
};

pub fn RingBuffer(comptime T: type) type {
    return struct {
        const Self = @This();

        buf: []T,
        head: usize = 0,
        tail: usize = 0,
        full: bool = false,

        pub fn init(allocator: Allocator, length: usize) !*Self {
            const self = try allocator.create(Self);
            self.* = .{
                .buf = try allocator.alloc(T, length),
            };
            return self;
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            allocator.free(self.buf);
            allocator.destroy(self);
        }

        pub fn is_empty(self: *const Self) bool {
            return !self.full and self.head == self.tail;
        }

        pub fn is_full(self: *const Self) bool {
            return self.full;
        }

        pub fn push(self: *Self, item: T) RingBufferError!void {
            if (self.is_full()) return RingBufferError.BufferFull;
            self.buf[self.head] = item;
            self.head = self.get_index(self.head + 1);
            if (self.head == self.tail) self.full = true;
        }

        pub fn pop(self: *Self) RingBufferError!T {
            if (self.is_empty()) return RingBufferError.BufferEmpty;
            const item = self.buf[self.tail];
            self.tail = self.get_index(self.tail + 1);
            if (self.full) self.full = false;
            return item;
        }

        pub fn reset(self: *Self) !void {
            self.head = 0;
            self.tail = 0;
            self.full = false;
        }

        fn get_index(self: *const Self, i: usize) usize {
            return i % self.buf.len;
        }
    };
}

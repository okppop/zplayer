const c = @import("c.zig").c;
const internal = @import("internal.zig");

const Self = @This();

ptr: *c.AVPacket,

pub fn init() !Self {
    const ptr = c.av_packet_alloc() orelse return internal.ffmpeg.AVError;
    return .{
        .ptr = ptr.?,
    };
}

pub fn deinit(self: *Self) void {
    c.av_packet_free(&self.ptr);
}

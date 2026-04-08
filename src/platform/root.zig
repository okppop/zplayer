pub const window = @import("window.zig");
pub const Event = @import("event.zig").Event;

const sdl3 = @import("c.zig").sdl3;
const std = @import("std");

pub fn init() !void {
    try std.testing.expect(sdl3.SDL_Init(sdl3.SDL_INIT_VIDEO));
}

pub const deinit = sdl3.SDL_Quit();

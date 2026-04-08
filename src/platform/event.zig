const sdl3 = @import("c.zig").sdl3;

pub const Event = union(enum) {
    quit,
    other,

    pub fn poll() ?Event {
        var event: sdl3.SDL_Event = undefined;
        if (sdl3.SDL_PollEvent(&event)) {
            return switch (event.type) {
                sdl3.SDL_EVENT_QUIT => .quit,
                else => .other,
            };
        } else {
            return null;
        }
    }
};

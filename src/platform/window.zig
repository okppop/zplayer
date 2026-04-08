const sdl3 = @import("c.zig").sdl3;
const std = @import("std");

const Self = @This();
window: *sdl3.SDL_Window,
renderer: *sdl3.SDL_Renderer,

pub fn init(title: [:0]const u8, width: i32, height: i32, is_resizable: bool) !Self {
    var window_flag: sdl3.SDL_WindowFlags = sdl3.SDL_WINDOW_HIDDEN;
    if (is_resizable) window_flag |= sdl3.SDL_WINDOW_RESIZABLE;

    var window: ?*sdl3.SDL_Window = undefined;
    var renderer: ?*sdl3.SDL_Renderer = undefined;
    try std.testing.expect(sdl3.SDL_CreateWindowAndRenderer(
        title,
        width,
        height,
        window_flag,
        &window,
        &renderer,
    ));
    errdefer sdl3.SDL_DestroyWindow(window);
    errdefer sdl3.SDL_DestroyRenderer(renderer);
    return .{
        .window = window.?,
        .renderer = renderer.?,
    };
}

pub fn deinit(self: *Self) void {
    sdl3.SDL_DestroyWindow(self.window);
    sdl3.SDL_DestroyRenderer(self.renderer);
}

pub fn show(self: *Self) !void {
    try std.testing.expect(sdl3.SDL_ShowWindow(self.window));
}

const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};

pub fn clear(self: *Self, color: Color) !void {
    try std.testing.expect(sdl3.SDL_SetRenderDrawColorFloat(
        self.renderer,
        color.r,
        color.g,
        color.b,
        color.a,
    ));
    try std.testing.expect(sdl3.SDL_RenderClear(self.renderer));
}

pub fn present(self: *Self) !void {
    try std.testing.expect(sdl3.SDL_RenderPresent(self.renderer));
}

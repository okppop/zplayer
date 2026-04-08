const std = @import("std");
const App = @import("app.zig");

pub fn main() !void {
    var app = try App.init(.{
        .title = "zplayer",
        .width = 800,
        .height = 600,
        .is_resizable = true,
    });
    defer app.deinit();

    try app.run();
}

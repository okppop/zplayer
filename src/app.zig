const platform = @import("platform");

pub const Config = struct {
    title: [:0]const u8,
    width: i32,
    height: i32,
    is_resizable: bool,
};

const Self = @This();
window: platform.Window,
is_running: bool,

pub fn init(config: Config) !Self {
    try platform.init();
    errdefer platform.deinit();

    var window = try platform.Window.init(
        config.title,
        config.width,
        config.height,
        config.is_resizable,
    );
    errdefer window.deinit();

    try window.show();

    return .{
        .window = window,
        .is_running = true,
    };
}

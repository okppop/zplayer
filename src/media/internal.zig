pub const ffmpeg = error{
    AVError,
};

pub fn check_ff_error(ret: i32) !void {
    if (ret < 0) return ffmpeg.AVError;
}

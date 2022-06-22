const std = @import("std");

pub fn panic(_: []const u8, _: ?*const std.builtin.StackTrace) noreturn {
    unreachable;
}

const size = [2]u32{960, 540};

pub const State = extern struct {
    pixels: [size[0]*size[1]][4]u8,

    // easier to export these to wasm than globals
    export fn width() u32 { return size[0]; }
    export fn height() u32 { return size[1]; }
};

export fn draw(dt: f32) void {
    const widthf: f32 = @intToFloat(f32, size[0]);
    const heightf: f32 = @intToFloat(f32, size[1]);
    var state = @intToPtr(*State, 2*std.mem.page_size);
    for (state.pixels) |*pix, i| {
        const dy = @floatToInt(usize, dt);
        const x = @intToFloat(f32, i / size[0]);
        const y = @intToFloat(f32, (i % size[0] + dy)%size[1]);
        pix[0] = @floatToInt(u8, x / widthf * 255);
        pix[1] = 255;
        pix[2] = @floatToInt(u8, y / heightf * 255);
        pix[3] = 255;
    }
}

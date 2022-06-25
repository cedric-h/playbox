const std = @import("std");

pub fn panic(_: []const u8, _: ?*const std.builtin.StackTrace) noreturn {
    unreachable;
}

const size = [2]u32{ 256, 256 };

pub const State = extern struct {
    pixels: [size[0] * size[1]][4]u8,

    // easier to export these to wasm than globals
    export fn width() u32 {
        return size[0];
    }
    export fn height() u32 {
        return size[1];
    }
};

const Ray = struct {
    origin: [3]f32,
    direction: [3]f32,
};

const eye = [3]f32{ 0, 0, 0 };

fn cross(v: [3]f32, o: [3]f32) [3]f32 {
    return [3]f32{ v[1] * o[2] - v[2] * o[1], v[2] * o[0] - v[0] * o[2], v[0] * o[1] - v[1] * o[0] };
}

fn add(a: [3]f32, b: [3]f32) [3]f32 {
    return [3]f32{
        a[0] + b[0],
        a[1] + b[1],
        a[2] + b[2],
    };
}

fn sub(a: [3]f32, b: [3]f32) [3]f32 {
    return [3]f32{
        a[0] - b[0],
        a[1] - b[1],
        a[2] - b[2],
    };
}

fn mulf(v: [3]f32, x: f32) [3]f32 {
    return [3]f32{
        v[0] * x,
        v[1] * x,
        v[2] * x,
    };
}

fn dot(a: [3]f32, b: [3]f32) f32 {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

fn magnitude(v: [3]f32) f32 {
    return @sqrt(dot(v, v));
}

fn norm(v: [3]f32) [3]f32 {
    const m = magnitude(v);
    return [3]f32{
        v[0] / m,
        v[1] / m,
        v[2] / m,
    };
}

const Quad = struct {
    pos: [3]f32,
    norm: [3]f32,
    tan: [3]f32,
    size: f32,
};

var quad: Quad = .{
    .pos = [3]f32{ 0, 0, 1 },
    .norm = [3]f32{ 0, 0, -1 },
    .tan = [3]f32{ 0, 1, 0 },
    .size = 0.25,
};

export fn draw(dt: f32) void {
    const widthf: f32 = @intToFloat(f32, size[0]);
    const heightf: f32 = @intToFloat(f32, size[1]);

    var state = @intToPtr(*State, 2 * std.mem.page_size);

    quad.norm = [3]f32{
        @cos(dt * 0.001),
        0,
        @sin(dt * 0.001),
    };

    for (state.pixels) |*pix, i| {
        const x = @intToFloat(f32, i / size[0]);
        const y = @intToFloat(f32, i % size[0]);

        const lookAt = [3]f32{ 0.5 - x / widthf, 0.5 - y / heightf, 1.0 };
        const look = Ray{
            .origin = eye,
            .direction = norm(lookAt),
        };

        // cast ray against quad

        // get time until plane intersection
        const d = dot(quad.pos, mulf(quad.norm, -1));
        const t = -(d + dot(quad.norm, look.origin)) / dot(quad.norm, look.direction);

        // didn't hit the plane
        if (t < 0) continue;

        // where the ray hits the surface
        const p = add(look.origin, mulf(look.direction, t));

        const to_p = sub(p, quad.pos);
        var u = dot(quad.tan, to_p);
        var v = dot(cross(quad.tan, quad.norm), to_p);
        u = u / quad.size + 0.5;
        v = v / quad.size + 0.5;

        var r = @floatToInt(u8, u * 255);
        var g = @floatToInt(u8, v * 255);
        if (u <= 0 or v <= 0) {
            r = 0;
            g = 0;
        }
        if (u >= 1 or v >= 1) {
            r = 0;
            g = 0;
        }

        // turn quad uv into color
        pix[0] = r;
        pix[1] = 0;
        pix[2] = g;
        pix[3] = 255;
    }
}

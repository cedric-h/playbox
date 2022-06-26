const std = @import("std");

pub fn panic(_: []const u8, _: ?*const std.builtin.StackTrace) noreturn {
    unreachable;
}

// extern fn print(f: f32) void;

const pixels = @ptrCast(*const [2048][1024][4]u8, @embedFile("../output_binary_RGB8.dat"));

const size = [2]u32{ 500, 500 };

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

// const Quad = struct {
//     pos: [3]f32,
//     norm: [3]f32,
//     tan: [3]f32,
//     size: f32,
// };

const Sphere = struct {
    pos: [3]f32,
    size: f32,
};

// var quad: Quad = .{
//     .pos = [3]f32{ 0, 0, 1 },
//     .norm = [3]f32{ 0, 0, -1 },
//     .tan = [3]f32{ 0, 1, 0 },
//     .size = 0.25,
// };

var sphere: Sphere = .{
    .pos = [3]f32{ 0, 0, 2 },
    .size = 0.5,
};

export fn draw(dt: f32) void {
    const widthf: f32 = @intToFloat(f32, size[0]);
    const heightf: f32 = @intToFloat(f32, size[1]);

    var state = @intToPtr(*State, 2 * std.mem.page_size);
    // quad.norm = norm([3]f32{
    //     @cos(dt * 0.002),
    //     @sin(dt * 0.002) / @cos(dt * 0.001),
    //     @sin(dt * 0.001),
    // });

    for (state.pixels) |*pix, i| {
        const x = @intToFloat(f32, i / size[0]);
        const y = @intToFloat(f32, i % size[0]);

        const lookAt = norm([3]f32{ 0.5 - x / widthf, 0.5 - y / heightf, 1.0 });
        const look = Ray{
            .origin = eye,
            .direction = lookAt,
        };

        {
            const color = @floatToInt(u8, 255 * @mod(@round(x / 20) + @round(y / 20), 2));
            pix[0] = color;
            pix[1] = color;
            pix[2] = color;
            pix[3] = 255;
        }

        // cast ray against quad

        // // get time until plane intersection
        // const d = dot(sphere.pos, mulf(quad.norm, -1));
        // const t = -(d + dot(quad.norm, look.origin)) / dot(quad.norm, look.direction);

        // const L = magnitude(sub(sphere.pos, look.origin));
        const L = sub(sphere.pos, look.origin);
        // const tc = dot([3]f32{ L, L, L }, look.direction);

        const t2 = dot(L, look.direction);

        // didn't hit the sphere
        if (t2 < 0) continue;

        const d2 = dot(L, L) - (t2 * t2);
        if (d2 > sphere.size * sphere.size) continue;

        const t3 = @sqrt(sphere.size * sphere.size - d2);
        const t0 = t2 - t3;

        // where the ray hits the surface
        const p = add(look.origin, mulf(look.direction, t0));

        const to_p = norm(sub(p, sphere.pos));
        var light_multip = dot(to_p, norm([3]f32{ @sin(dt * 0.001), 0, @cos(dt * 0.001) }));

        const scatter = 0.2;
        light_multip = @maximum(light_multip, 0.0) * (1 - scatter) + scatter;
        // light_multip += std.math.pow(f32, light_multip, 64.0);
        // light_multip += @exp(light_multip / 20);
        light_multip = @minimum(light_multip, 1.0);

        // var u = std.math.atan2(f32, p[2], p[0]) / std.math.pi;
        // var v = std.math.acos(p[1] / sphere.size) / (2 * std.math.pi);

        // var u = std.math.atan2(f32, p[2], p[0]) / (1 * std.math.pi);
        // var v = std.math.acos(p[1] / sphere.size) / (3 * std.math.pi);

        var u = 0.5 + std.math.atan2(f32, p[0], p[2]) / (2 * std.math.pi);
        var v = 0.5 + std.math.asin(p[1]) / (3 * std.math.pi);

        // var u = dot(quad.tan, to_p);
        // var v = dot(cross(quad.tan, quad.norm), to_p);
        // u = u / sphere.size + 0.5;
        // v = v / sphere.size + 0.5;

        // u += dt * 0.00001;
        v += dt * 0.00003;

        // print(u);
        // print(v);

        const pixel_x = @floatToInt(usize, u * 2048);
        const pixel_y = @floatToInt(usize, v * 1024);
        const color = @intToFloat(f32, pixels[pixel_x][pixel_y][0]) / 255;

        var r = @floatToInt(u8, color * 255 * light_multip);
        var g = @floatToInt(u8, color * 255 * light_multip);
        // if (u <= 0 or v <= 0) {
        //     r = 0;
        //     g = 0;
        // }
        // if (u >= 1 or v >= 1) {
        //     r = 0;
        //     g = 0;
        // }

        // turn quad uv into color
        pix[0] = r;
        pix[1] = 0;
        pix[2] = g;
        pix[3] = 255;
    }
}

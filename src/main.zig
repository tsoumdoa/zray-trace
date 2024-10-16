const std = @import("std");
const stdout = std.io.getStdOut().writer();
const format = std.fmt.format;
const vec3 = @import("vec3.zig").vec3;
const dot = @import("vec3.zig").Dot;
const point3 = @import("vec3.zig").point3;
const unitVector = @import("vec3.zig").unitVector;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;
const print = std.debug.print;

const Ray = struct {
    origin: point3,
    direction: vec3,

    fn pointAtParameter(self: Ray, t: f32) @Vector(3, f32) {
        const c = self.direction.mul(t);
        return self.origin.e.* + c.e.*;
    }
};

fn hitSphere(ray: *Ray, center: point3, radius: f32) f32 {
    var oc = center.e.* - ray.origin.e.*;
    const oc_vec3 = vec3.init(&oc);
    const a = ray.direction.length_sqr();
    const h = dot(ray.direction, oc_vec3);
    const c = oc_vec3.length_sqr() - (radius * radius);
    const discriminant = (h * h) - (a * c);

    if (discriminant < 0) {
        return -1.0;
    } else {
        const r = (h - @sqrt(discriminant)) / a;
        return r;
    }
}

const ASPECT_RATIO: f32 = 16.0 / 9.0;
const image_width = 400;
const image_height = @as(usize, @intFromFloat(@as(f32, @floatFromInt(image_width)) / ASPECT_RATIO));
const image_width_splat = @as(@Vector(3, f32), @splat(@as(f32, @floatFromInt(image_width))));
const image_height_splat = @as(@Vector(3, f32), @splat(@as(f32, @floatFromInt(image_height))));

const focal_length: f32 = 1.0;
const viewport_height: f32 = 2.0;
const viewport_width = viewport_height * @as(f32, @floatFromInt(image_width)) / @as(f32, @floatFromInt(image_height));

const viewport_u = @Vector(3, f32){
    viewport_width,
    0,
    0,
};
const viewport_v = @Vector(3, f32){
    0,
    -viewport_height,
    0,
};

const viewport_u_half = viewport_u / @as(@Vector(3, f32), @splat(2));
const viewport_v_half = viewport_v / @as(@Vector(3, f32), @splat(2));

const pixel_delta_u = viewport_u / image_width_splat;
const pixel_delta_v = viewport_v / image_height_splat;

const delta_uv = pixel_delta_u + pixel_delta_v;
const delta_uv_half_splat = @as(@Vector(3, f32), @splat(0.5)) * delta_uv;

pub fn main() !void {
    assert(image_height >= 1);

    var camera_center = @Vector(3, f32){ 0, 0, 0 };

    const viewport_upper_left = camera_center - @Vector(3, f32){ 0, 0, focal_length } - viewport_u_half - viewport_v_half;
    const pxel00_loc = viewport_upper_left + delta_uv_half_splat;

    const ppm = try std.fs.cwd().createFile("image.ppm", .{});
    defer ppm.close();

    try format(ppm.writer(), "P3\n {d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        try stdout.print("\x1BM \x1b[1;37m Scanlines remaining: {d}\n", .{image_height - j});
        for (0..image_width) |i| {
            const i_splat = @as(@Vector(3, f32), @splat(@as(f32, @floatFromInt(i))));
            const j_splat = @as(@Vector(3, f32), @splat(@as(f32, @floatFromInt(j))));

            const pixel_center = pxel00_loc + (i_splat * pixel_delta_u) + (j_splat * pixel_delta_v);
            var ray_direction = pixel_center - camera_center;

            var ray = Ray{ .origin = vec3.init(&camera_center), .direction = vec3.init(&ray_direction) };
            var center = @Vector(3, f32){ 0, 0, -1 };

            const t = hitSphere(&ray, vec3.init(&center), 0.5);
            if (t > 0) {
                var v = ray.pointAtParameter(t) - center;
                const v3 = vec3.init(&v);
                const n = unitVector(v3);
                const r_int = @as(u8, @intFromFloat(0.5 * (n.x() + 1) * 255));
                const g_int = @as(u8, @intFromFloat(0.5 * (n.y() + 1) * 255));
                const b_int = @as(u8, @intFromFloat(0.5 * (n.z() + 1) * 255));
                try std.fmt.format(ppm.writer(), "{d} {d} {d}\n", .{ r_int, g_int, b_int });
            } else {
                const ray_vec = vec3.init(&ray_direction);
                const unit_direction = unitVector(ray_vec);
                const a = 0.5 * (unit_direction.y() + 1);
                const start_col = @as(@Vector(3, f32), @splat(1.0 - a));
                const end_col = @Vector(3, f32){ a * 0.5, a * 0.7, a * 1.0 };
                const col = start_col + end_col;
                const r_int = @as(u8, @intFromFloat(col[0] * 255));
                const g_int = @as(u8, @intFromFloat(col[1] * 255));
                const b_int = @as(u8, @intFromFloat(col[2] * 255));
                try std.fmt.format(ppm.writer(), "{d} {d} {d}\n", .{ r_int, g_int, b_int });
            }
        }
    }
}

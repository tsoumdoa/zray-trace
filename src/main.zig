const std = @import("std");
const stdout = std.io.getStdOut().writer();
const format = std.fmt.format;
const vec3 = @import("vec3.zig").vec3;
const point3 = @import("vec3.zig").point3;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;
const print = std.debug.print;

const Ray = struct {
    origin: point3,
    direction: vec3,

    fn pointAtParameter(self: Ray, t: f32) point3 {
        return self.origin.add(self.direction.mul(t));
    }
};

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
    var gpa_impl: std.heap.GeneralPurposeAllocator(.{}) = .{};
    const gpa = gpa_impl.allocator();

    defer _ = gpa_impl.deinit();

    var arena_impl = std.heap.ArenaAllocator.init(gpa);
    const arena = arena_impl.allocator();
    defer arena_impl.deinit();
    _ = arena;

    var ray_list = ArrayList(*Ray).init(gpa);
    defer ray_list.deinit();

    const camera_center = @Vector(3, f32){ 0, 0, 0 };

    const viewport_upper_left = camera_center - @Vector(3, f32){ 0, 0, focal_length } - viewport_u_half - viewport_v_half;
    const pxel00_loc = viewport_upper_left + delta_uv_half_splat;

    // for (0..image_width) |i| {
    //     for (0..image_height) |j| {
    //         const src_vec = try arena.create(@Vector(3, f32));
    //         src_vec.* = @Vector(3, f32){ @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(j)), 0 };
    //
    //         const dir_vec = try arena.create(@Vector(3, f32));
    //         dir_vec.* = @Vector(3, f32){ 0, 0, 1 };
    //
    //         const src = try arena.create(point3);
    //         src.* = point3.init(src_vec);
    //
    //         const dir = try arena.create(vec3);
    //         dir.* = vec3.init(dir_vec);
    //
    //         const ray = try arena.create(Ray);
    //         ray.* = Ray{ .origin = src, .direction = dir };
    //         try ray_list.append(ray);
    //     }
    // }

    const ppm = try std.fs.cwd().createFile("image.ppm", .{});
    defer ppm.close();

    // for (ray_list.items) |ray| {
    // try stdout.print("ray: {d} {d} {d}\n", .{ ray.origin.x(), ray.origin.y(), ray.origin.z() });
    // }

    try format(ppm.writer(), "P3\n {d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        try stdout.print("\x1BM \x1b[1;37m Scanlines remaining: {d}\n", .{image_height - j});
        for (0..image_width) |i| {
            const i_splat = @as(@Vector(3, f32), @splat(@as(f32, @floatFromInt(i))));
            const j_splat = @as(@Vector(3, f32), @splat(@as(f32, @floatFromInt(j))));

            const piexel_center = pxel00_loc + (i_splat * pixel_delta_u) + (j_splat * pixel_delta_v);
            const ray_direction = piexel_center - camera_center;

            const a = 0.5 * (ray_direction[1] + 1);

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

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
const Ray = @import("./ray.zig").Ray;
const HitRecord = @import("./hit_record.zig").HitRecord;
const Sphere = @import("./sphere.zig").Sphere;

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

const SAMPLING_MULTIPLIER = 2;

// camera
const focal_length: f32 = 1.0;
const viewport_height: f32 = 2.0;
const viewport_width = viewport_height * @as(f32, @floatFromInt(image_width)) / @as(f32, @floatFromInt(image_height));
var camera_center = @Vector(3, f32){ 0, 0, 0 };

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
const delta_uv_half_splat = @as(@Vector(3, f32), @splat(0.5)) * (pixel_delta_u + pixel_delta_v);

pub fn main() !void {
    assert(image_height >= 1);

    const viewport_upper_left = camera_center - @Vector(3, f32){ 0, 0, focal_length } - viewport_u_half - viewport_v_half;
    const pxel00_loc = viewport_upper_left + delta_uv_half_splat;

    //allocator stuff
    var gpa_impl: std.heap.GeneralPurposeAllocator(.{}) = .{};
    const gpa = gpa_impl.allocator();
    defer _ = gpa_impl.deinit();

    var arena_impl = std.heap.ArenaAllocator.init(gpa);
    const arena = arena_impl.allocator();

    const World = union {
        sphere: *Sphere,
    };

    var world = ArrayList(World).init(gpa);
    defer world.deinit();

    var center_one = @Vector(3, f32){ 0, 0, -1 };
    var sphere_one = try Sphere.init(point3.init(&center_one), 0.5);
    try world.append(World{ .sphere = &sphere_one });
    var center_two = @Vector(3, f32){ 0.0, -2, -1 };
    var sphere_two = try Sphere.init(point3.init(&center_two), 1);
    try world.append(World{ .sphere = &sphere_two });

    var texture_buffer = try ArrayList(ArrayList(@Vector(3, u16))).initCapacity(gpa, image_height);
    defer texture_buffer.deinit();

    for (0..image_height * SAMPLING_MULTIPLIER) |j| {
        var row_buffer = try ArrayList(@Vector(3, u16)).initCapacity(arena, image_width);
        for (0..image_width * SAMPLING_MULTIPLIER) |i| {
            var v = @Vector(3, u16){ 0, 0, 0 };

            const i_splat = @as(@Vector(3, f32), @splat(@as(f32, @floatFromInt(i))));
            const j_splat = @as(@Vector(3, f32), @splat(@as(f32, @floatFromInt(j))));

            const pixel_center = pxel00_loc + (i_splat * pixel_delta_u) + (j_splat * pixel_delta_v);
            var ray_direction = pixel_center - camera_center;

            var ray = Ray{ .origin = vec3.init(&camera_center), .direction = vec3.init(&ray_direction) };

            const hit_record = try arena.create(HitRecord);
            const hr = HitRecord.init(point3.init(&camera_center), &ray.direction);
            hit_record.* = hr;

            var hit_anything = false;
            var closest_so_far = std.math.inf(f32);

            for (world.items) |obj| {
                const hit = try obj.sphere.hit(&ray, 0, closest_so_far, hit_record, arena);
                if (hit) {
                    hit_anything = true;
                    closest_so_far = hit_record.t;
                }
            }

            if (hit_anything) {
                const r = 0.5 * ((hit_record.normal.x() / hit_record.normal.length_sqr()) + 1) * 255;
                const g = 0.5 * ((hit_record.normal.y() / hit_record.normal.length_sqr()) + 1) * 255;
                const b = 0.5 * ((hit_record.normal.z() / hit_record.normal.length_sqr()) + 1) * 255;
                v[0] = @as(u16, @intFromFloat(r));
                v[1] = @as(u16, @intFromFloat(g));
                v[2] = @as(u16, @intFromFloat(b));
            } else {
                const ray_vec = vec3.init(&ray_direction);
                const unit_direction = unitVector(ray_vec);
                const a = 0.5 * (unit_direction.y() + 1);
                const start_col = @as(@Vector(3, f32), @splat(1.0 - a));
                const end_col = @Vector(3, f32){ a * 0.5, a * 0.7, a * 1.0 };
                const col = start_col + end_col;
                v[0] = @as(u16, @intFromFloat(col[0] * 255));
                v[1] = @as(u16, @intFromFloat(col[1] * 255));
                v[2] = @as(u16, @intFromFloat(col[2] * 255));
            }
            try row_buffer.append(v);
        }
        try texture_buffer.append(row_buffer);
    }

    //write ppm
    const ppm = try std.fs.cwd().createFile("image.ppm", .{});
    defer ppm.close();
    try format(ppm.writer(), "P3\n {d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        try stdout.print("\x1BM \x1b[1;37m Scanlines remaining: {d}\n", .{image_height - j});
        for (0..image_width) |i| {
            const i_current = texture_buffer.items[j].items[i];
            const i_next_current = texture_buffer.items[j].items[i + 1];
            const j_current = texture_buffer.items[j + 1].items[i];
            const j_next_current = texture_buffer.items[j].items[i];

            const i_sample = (i_current + i_next_current);
            const j_sample = (j_current + j_next_current);
            const average = (i_sample + j_sample) / @as(@Vector(3, u16), @splat(@as(u8, 4)));

            try std.fmt.format(ppm.writer(), "{d} {d} {d}\n", .{ average[0], average[1], average[2] });
        }
    }
    defer arena_impl.deinit();
}

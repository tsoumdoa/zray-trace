const std = @import("std");
const stdout = std.io.getStdOut().writer();
const format = std.fmt.format;
const vec3 = @import("vec3.zig").vec3;
const point3 = @import("vec3.zig").point3;
const ArrayList = std.ArrayList;

const Ray = struct {
    origin: *point3,
    direction: *vec3,

    fn pointAtParameter(self: Ray, t: f32) point3 {
        return self.origin.add(self.direction.mul(t));
    }
};

pub fn main() !void {
    var gpa_impl: std.heap.GeneralPurposeAllocator(.{}) = .{};
    const gpa = gpa_impl.allocator();

    defer _ = gpa_impl.deinit();

    var arena_impl = std.heap.ArenaAllocator.init(gpa);
    const arena = arena_impl.allocator();
    defer arena_impl.deinit();

    const image_width = 256;
    const image_height = 256;

    var ray_list = ArrayList(*Ray).init(gpa);
    defer ray_list.deinit();

    for (0..image_width) |i| {
        for (0..image_height) |j| {
            const src_vec = try arena.create(@Vector(3, f32));
            src_vec.* = @Vector(3, f32){ @as(f32, @floatFromInt(i)), @as(f32, @floatFromInt(j)), 0 };

            const dir_vec = try arena.create(@Vector(3, f32));
            dir_vec.* = @Vector(3, f32){ 0, 0, 1 };

            const src = try arena.create(point3);
            src.* = point3.init(src_vec);

            const dir = try arena.create(vec3);
            dir.* = vec3.init(dir_vec);

            const ray = try arena.create(Ray);
            ray.* = Ray{ .origin = src, .direction = dir };
            try ray_list.append(ray);
        }
    }

    const ppm = try std.fs.cwd().createFile("image.ppm", .{});
    defer ppm.close();

    for (ray_list.items) |ray| {
        try stdout.print("ray: {d} {d} {d}\n", .{ ray.origin.x(), ray.origin.y(), ray.origin.z() });
    }

    try format(ppm.writer(), "P3\n {d} {d}\n255\n", .{ image_width, image_height });

    // for (0..image_width) |j| {
    //     try stdout.print("\x1BM \x1b[1;37m Scanlines remaining: {d}\n", .{image_height - j});
    //     for (0..image_height) |i| {
    //         const r_int = i;
    //         const g_int = j;
    //         const b_int = 0;
    //         try std.fmt.format(ppm.writer(), "{d} {d} {d}\n", .{ r_int, g_int, b_int });
    //     }
    // }
}

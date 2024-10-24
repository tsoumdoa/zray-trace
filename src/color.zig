const std = @import("std");
const Ray = @import("./ray.zig").Ray;
const HitRecord = @import("./hit_record.zig").HitRecord;
const World = @import("./world.zig").World;
const vec3 = @import("./vec3.zig").vec3;
const unitVector = @import("./vec3.zig").unitVector;
const dot = @import("./vec3.zig").Dot;

pub fn Color(ray: *Ray, hit_record: *HitRecord, counts: usize, world: World, arena: std.mem.Allocator, rand: std.rand) !@Vector(3, u16) {
    if (counts <= 0) {
        return @Vector(3, u16){ 0, 0, 0 };
    }

    const new_ray = try arena.create(Ray);
    new_ray.* = ray.*;
    const hit = try world.hit(new_ray, hit_record, arena);

    if (hit) {
        var rand_vec = @Vector(3, f32){ undefined, undefined, undefined };
        const normalized_normal_vec = unitVector(hit_record.normal.*);

        while (true) {
            var c = @Vector(3, f32){
                (rand.float(f32) - 0.5) * 2,
                (rand.float(f32) - 0.5) * 2,
                (rand.float(f32) - 0.5) * 2,
            };

            const candidate = vec3.init(&c);
            const length_sqr = candidate.length_sqr();

            if (1e-160 < length_sqr and length_sqr <= 1.0) {
                if (dot(candidate, normalized_normal_vec) > 0) {
                    rand_vec = unitVector(candidate).e.*;
                } else {
                    rand_vec = unitVector(candidate.negative()).e.*;
                }
                break;
            }
        }
        new_ray.direction = vec3.init(&rand_vec);
        const v = try arena.create(@Vector(3, u16));
        const c = try Color(new_ray, hit_record, counts - 1, world, arena, rand);
        const r = 0.5 * @as(f32, @floatFromInt(c[0]));
        const g = 0.5 * @as(f32, @floatFromInt(c[1]));
        const b = 0.5 * @as(f32, @floatFromInt(c[2]));
        v[0] = @as(u16, @intFromFloat(r));
        v[1] = @as(u16, @intFromFloat(g));
        v[2] = @as(u16, @intFromFloat(b));
        return v.*;
    } else {
        const unit_direction = unitVector(new_ray.direction);
        const a = 0.5 * (unit_direction.y() + 1);
        const start_col = @as(@Vector(3, f32), @splat(1.0 - a));
        const end_col = @Vector(3, f32){ a * 0.5, a * 0.7, a * 1.0 };
        const col = start_col + end_col;
        const v = try arena.create(@Vector(3, u16));
        v[0] = @as(u16, @intFromFloat(0.5 * col[0] * 255));
        v[1] = @as(u16, @intFromFloat(0.5 * col[1] * 255));
        v[2] = @as(u16, @intFromFloat(0.5 * col[2] * 255));
        return v.*;
    }
}

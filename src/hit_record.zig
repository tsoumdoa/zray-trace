const point3 = @import("./vec3.zig").point3;
const vec3 = @import("./vec3.zig").vec3;
const Ray = @import("./ray.zig").Ray;
const dot = @import("./vec3.zig").Dot;
const std = @import("std");

pub const HitRecord = struct {
    const Self = @This();
    p: *point3,
    normal: *vec3,
    t: f32,

    pub fn init(origin: *point3, direction: *vec3) Self {
        return Self{
            .p = origin,
            .normal = direction,
            .t = undefined,
        };
    }

    pub inline fn setFaceNormal(self: Self, ray: *const *Ray, normal: *vec3) void {
        const is_front_face = dot(ray.*.direction, normal.*) > 0;
        if (!is_front_face) {
            self.normal.* = normal.*;
        } else {
            _ = normal.negative();
            self.normal.* = normal.*;
        }
    }
};

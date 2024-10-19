const vec3 = @import("vec3.zig").vec3;
const point3 = @import("vec3.zig").point3;
const Ray = @import("ray.zig").Ray;
const hit_record = @import("hit_record.zig").HitRecord;
const dot = @import("vec3.zig").Dot;
const std = @import("std");

pub const Sphere = struct {
    const Self = @This();

    center: vec3,
    radius: f32,

    pub fn init(center: point3, radius: f32) !Self {
        return Self{
            .center = center,
            .radius = radius,
        };
    }

    pub fn hit(self: Self, ray: *Ray, ray_tmin: f32, ray_tmax: f32, rec: *hit_record, allocator: std.mem.Allocator) !bool {
        var oc = self.center.e.* - ray.origin.e.*;
        const oc_vec3 = vec3.init(&oc);
        const a = ray.direction.length_sqr();
        const h = dot(ray.direction, oc_vec3);
        const c = oc_vec3.length_sqr() - (self.radius * self.radius);
        const discriminant = (h * h) - (a * c);

        if (discriminant < 0) return false;

        const sqrtd = @sqrt(discriminant);
        const root = (h - sqrtd) / a;
        if (root <= ray_tmin or ray_tmax <= root) {
            const reversed_root = (h + sqrtd) / a;
            if (root <= ray_tmin or ray_tmax <= reversed_root) return false;
        }

        rec.t = root;
        rec.p = ray.pointAtParameter(root);

        const v = try allocator.create(@Vector(3, f32));
        const outward_normal = (rec.p.e.* + self.center.e.*) / @as(@Vector(3, f32), @splat(self.radius));
        v.* = outward_normal;
        const vec = try allocator.create(vec3);
        vec.* = vec3.init(v);

        rec.setFaceNormal(ray, vec);

        return true;
    }
};

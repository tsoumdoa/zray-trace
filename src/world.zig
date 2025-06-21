const std = @import("std");
const Sphere = @import("./sphere.zig").Sphere;
const ArrayList = std.ArrayList;
const Ray = @import("./ray.zig").Ray;
const hit_record = @import("./hit_record.zig").HitRecord;
const vec3 = @import("./vec3.zig").vec3;

// const objectTypes = union {
//     sphere: *Sphere,
// };

pub const World = struct {
    const Self = @This();
    objects: ArrayList(*Sphere),

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .objects = ArrayList(*Sphere).init(allocator),
        };
    }

    pub fn add(self: *Self, obj: *Sphere) !void {
        try self.objects.append(obj);
    }

    pub inline fn hit(self: Self, ray: *Ray, rec: *hit_record, allocator: std.mem.Allocator) !bool {
        var hit_anything = false;
        const ray_tmin = 0;
        var closest_so_far = std.math.inf(f32);

        for (self.objects.items) |obj| {
            const has_hit = try obj.hit(&ray, ray_tmin, closest_so_far, rec, allocator);
            if (has_hit) {
                hit_anything = true;
                closest_so_far = rec.t;
                var normal = (rec.p.e.* - obj.*.center.e.*) / @as(@Vector(3, f32), @splat(obj.*.radius));
                rec.normal.* = vec3.init(&normal);
            }
        }
        return hit_anything;
    }
};

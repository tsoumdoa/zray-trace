const point3 = @import("./vec3.zig").point3;
const vec3 = @import("./vec3.zig").vec3;
pub const Ray = struct {
    const Self = @This();
    origin: point3,
    direction: vec3,

    pub fn pointAtParameter(self: Ray, t: f32) @Vector(3, f32) {
        const c = self.direction.mul(t);
        const p = self.origin.e.* + c.e.*;
        return p;
    }
};

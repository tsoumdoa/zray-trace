const point3 = @import("./vec3.zig").point3;
const vec3 = @import("./vec3.zig").vec3;
pub const Ray = struct {
    const Self = @This();
    origin: point3,
    direction: vec3,

    pub fn pointAtParameter(self: Ray, t: f32) point3 {
        const c = self.direction.mul(t);
        var p = self.origin.e.* + c.e.*;
        return point3.init(&p);
    }
};

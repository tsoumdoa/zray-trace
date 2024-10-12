const std = @import("std");

pub const vec3 = struct {
    const Self = @This();
    e: *@Vector(3, f32),

    pub fn init(e: *@Vector(3, f32)) Self {
        return Self{ .e = e };
    }

    pub fn x(self: Self) f32 {
        return self.e[0];
    }
    pub fn y(self: Self) f32 {
        return self.e[1];
    }
    pub fn z(self: Self) f32 {
        return self.e[2];
    }

    pub fn negative(self: Self) Self {
        self.e.* = @as(@Vector(3, f32), @splat(-1)) * self.e.*;
        return self;
    }

    pub fn add(self: Self, scala: f32) Self {
        self.e.* = @as(@Vector(3, f32), @splat(scala)) + self.e.*;
        return self;
    }

    pub fn mul(self: Self, scala: f32) Self {
        self.e.* = @as(@Vector(3, f32), @splat(scala)) * self.e.*;
        return self;
    }

    pub fn div(self: Self, scala: f32) Self {
        self.e.* = @as(@Vector(3, f32), @splat(1 / scala)) * self.e.*;
        return self;
    }

    pub fn length(self: Self) f32 {
        return self.e[0] * self.e[0] + self.e[1] * self.e[1] + self.e[2] * self.e[2];
    }

    pub fn length_sqr(self: Self) f32 {
        return @sqrt(self.e[0] * self.e[0] + self.e[1] * self.e[1] + self.e[2] * self.e[2]);
    }
};

pub const point3 = vec3;

pub inline fn add(u: vec3, v: vec3) vec3 {
    return vec3(u.x + v.x, u.y + v.y, u.z + v.z);
}

const test_alloc = std.testing.allocator;

test "vec3 init test" {
    const v = try test_alloc.create(@Vector(3, f32));
    defer test_alloc.destroy(v);
    v.* = .{ 1, 2, 3 };
    const vec = vec3.init(v);
    try std.testing.expectEqual(@as(f32, 1), vec.e[0]);
    try std.testing.expectEqual(@as(f32, 2), vec.e[1]);
    try std.testing.expectEqual(@as(f32, 3), vec.e[2]);
}

test "vec3 negative test" {
    const v = try test_alloc.create(@Vector(3, f32));
    defer test_alloc.destroy(v);
    v.* = .{ 1, 2, 3 };
    const vec = vec3.init(v);
    _ = vec.negative();
    try std.testing.expectEqual(@as(f32, -1), vec.e[0]);
    try std.testing.expectEqual(@as(f32, -2), vec.e[1]);
    try std.testing.expectEqual(@as(f32, -3), vec.e[2]);
}

test "vec3 add test" {
    const v = try test_alloc.create(@Vector(3, f32));
    defer test_alloc.destroy(v);
    v.* = .{ 1, 2, 3 };
    const vec = vec3.init(v);
    _ = vec.add(5);
    try std.testing.expectEqual(@as(f32, 6), vec.e[0]);
    try std.testing.expectEqual(@as(f32, 7), vec.e[1]);
    try std.testing.expectEqual(@as(f32, 8), vec.e[2]);
}

test "vec3 mul test" {
    const v = try test_alloc.create(@Vector(3, f32));
    defer test_alloc.destroy(v);
    v.* = .{ 1, 2, 3 };
    const vec = vec3.init(v);
    _ = vec.mul(5);
    try std.testing.expectEqual(@as(f32, 5), vec.e[0]);
    try std.testing.expectEqual(@as(f32, 10), vec.e[1]);
    try std.testing.expectEqual(@as(f32, 15), vec.e[2]);
}

test "vec3 div test" {
    const v = try test_alloc.create(@Vector(3, f32));
    defer test_alloc.destroy(v);
    v.* = .{ 1, 2, 3 };
    const vec = vec3.init(v);
    _ = vec.div(5);
    try std.testing.expectEqual(@as(f32, 0.2), vec.e[0]);
    try std.testing.expectEqual(@as(f32, 0.4), vec.e[1]);
    try std.testing.expectEqual(@as(f32, 0.6), vec.e[2]);
}

test "vec3 length test" {
    const v = try test_alloc.create(@Vector(3, f32));
    defer test_alloc.destroy(v);
    v.* = .{ 3, 4, 5 };
    const vec = vec3.init(v);
    try std.testing.expectEqual(@as(f32, (3 * 3 + 4 * 4 + 5 * 5)), vec.length());
}

test "vec3 length sqr test" {
    const v = try test_alloc.create(@Vector(3, f32));
    defer test_alloc.destroy(v);
    v.* = .{ 3, 4, 5 };
    const vec = vec3.init(v);
    try std.testing.expectEqual(@as(f32, @sqrt(3.0 * 3.0 + 4.0 * 4.0 + 5.0 * 5.0)), vec.length_sqr());
}

const std = @import("std");
const stdout = std.io.getStdOut().writer();
const format = std.fmt.format;

pub fn main() !void {
    const image_width = 256;
    const image_height = 256;

    const ppm = try std.fs.cwd().createFile("image.ppm", .{});
    defer ppm.close();

    try format(ppm.writer(), "P3\n {d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_width) |x| {
        for (0..image_height) |y| {
            const r_int = x;
            const g_int = y;
            const b_int = 0;
            try std.fmt.format(ppm.writer(), "{d} {d} {d}\n", .{ r_int, g_int, b_int });
        }
    }
}

const std = @import("std");
const stdout = std.io.getStdOut().writer();
const format = std.fmt.format;

pub fn main() !void {
    const image_width = 256;
    const image_height = 256;

    const ppm = try std.fs.cwd().createFile("image.ppm", .{});
    defer ppm.close();

    try format(ppm.writer(), "P3\n {d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_width) |j| {
        try stdout.print("\x1BM \x1b[1;37m Scanlines remaining: {d}\n", .{image_height - j});
        for (0..image_height) |i| {
            const r_int = i;
            const g_int = j;
            const b_int = 0;
            try std.fmt.format(ppm.writer(), "{d} {d} {d}\n", .{ r_int, g_int, b_int });
        }
    }
}

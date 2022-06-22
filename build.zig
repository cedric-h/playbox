const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const lib = b.addSharedLibrary(
        "wasmsock", "src/main.zig", .unversioned);
    std.debug.print("building in {}\n", .{mode});
    lib.strip = mode == std.builtin.Mode.ReleaseSmall;
    lib.initial_memory =
         (@sizeOf(@import("src/main.zig").State)
             / (1 << 16) + 3)
             * (1 << 16);
    lib.setTarget(b.standardTargetOptions(.{}));
    lib.setBuildMode(mode);
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}

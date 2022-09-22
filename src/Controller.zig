const std = @import("std");
const w4 = @import("wasm4.zig");

const Self = @This();

const Gamepad = packed struct {
    x: bool = false,
    y: bool = false,
    padding: u2 = 0,
    left: bool = false,
    right: bool = false,
    down: bool = false,
    up: bool = false,
};

previous: u8 = 0,

held: Gamepad = .{},
released: Gamepad = .{},

pub fn update(self: *Self, gamepad: *const u8) void {
    self.previous = @bitCast(u8, self.held);
    self.held = @bitCast(Gamepad, gamepad.*);

    self.released = @bitCast(Gamepad, self.previous & gamepad.* ^ self.previous);
}

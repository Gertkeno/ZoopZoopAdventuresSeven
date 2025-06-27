const w4 = @import("wasm4.zig");
const std = @import("std");
const Zoop = @import("Zoopzoop.zig");
const Self = @This();

const flowir_art = [_]u8{
    0b11100111,
    0b11100111,
    0b10011001,
    0b10011001,
    0b11100111,
    0b11100111,
    0b11001111,
    0b11110011,
    0b11101111,
    0b11110111,
};

const withered_art = [_]u8{
    0b11111111,
    0b11111111,
    0b11111111,
    0b11111111,
    0b11111111,
    0b11111111,
    0b11001111,
    0b11110011,
    0b11101111,
    0b11110111,
};

// coordinates (x, y)
// maxmimum right 160, down 160
// minimum left 0, up 0

extern const frame: u32;
pub const width = 8;
pub const height = 10;

x: i32 = 40,
y: i32 = 75,

withered: bool = false,

pub fn collides(flower: Self, zoop: Zoop) bool {
    // start X axis checks left -> right
    if (zoop.x + Zoop.width < flower.x) {
        return false;
    } else if (zoop.x > flower.x + width) {
        return false;
    }

    // start Y axis checks top -> bottom
    if (zoop.y + Zoop.height < flower.y) {
        return false;
    } else if (zoop.y > flower.y + height) {
        return false;
    }

    // couldn't find a reason they aren't touhing!
    return true;
}

pub fn update(self: *Self) void {
    if (self.withered) {
        w4.blit(&withered_art, self.x, self.y, width, height, w4.BLIT_1BPP);
    } else {
        const flippy = if (frame & 0b10000 > 0) w4.BLIT_FLIP_X else 0;
        w4.blit(&flowir_art, self.x, self.y, width, height, w4.BLIT_1BPP | flippy);
    }
}

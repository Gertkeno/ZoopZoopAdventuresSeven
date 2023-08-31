const std = @import("std");
const w4 = @import("wasm4.zig");
const Controller = @import("Controller.zig");
const Song = @import("Song.zig");

const Self = @This();

const zoop_art_1bpp = [_]u16{
    @byteSwap(0b11110010_11001001),
    @byteSwap(0b11101101_01101011),
    @byteSwap(0b11000000_00000000),
    @byteSwap(0b11010010_01111110),
    @byteSwap(0b11010010_01011010),
    @byteSwap(0b00010010_01111110),
    @byteSwap(0b00010010_01011010),
    @byteSwap(0b11010010_01000010),
    @byteSwap(0b11010010_01111110),
    @byteSwap(0b11000000_00000000),
    @byteSwap(0b11111001_11001111),
};

// coordinates (x, y)
// maxmimum right 160, down 160
// minimum left 0, up 0

x: i32,
y: i32,

width: i32 = 16,
height: i32 = 11,

text_color: u16,
color: u16,
yurm_anim_time: u32 = 0,
revive_anim_time: u32 = 0,
pollin: u16 = 0,
down: bool = false,

score_display: [12]u8 = "Pollin:     ".*,
controller: Controller = .{},

const speed = 1;
const falling_roll = Song.compile_roll("C# A3 G3 - | C A3 G3 -", 12);
var falling_song = Song.init(&falling_roll, .Pulse1, 1, 66);

extern const frame: u32;

pub fn update(self: *Self) void {
    if (self.down) {
        // bee falls down
        self.y += 1;
        if (self.y >= 160 - self.height) {
            self.y = 160 - self.height;
        } else {
            // zig zag falling
            self.x += if (frame & 0b1000 > 0) @as(i32, 1) else -1;
            if (!falling_song.update()) {
                falling_song.reset();
            }
        }
    } else {
        // bee is healthy
        // zoop responds to controls

        // left-right X axis
        if (self.controller.held.right) {
            self.x += speed;
            if (self.x >= 160 - self.width) {
                self.x = 157 - self.width;
            }
        }
        if (self.controller.held.left) {
            self.x -= speed;
            if (self.x <= 0) {
                self.x = 3;
            }
        }

        // up-down Y axis
        if (self.controller.held.up) {
            self.y += speed;
            if (self.y >= 160 - self.height) {
                self.y = 157 - self.height;
            }
        }
        if (self.controller.held.down) {
            self.y -= speed;
            if (self.y <= 0) {
                self.y = 3;
            }
        }
    }

    // draw the zoop
    w4.DRAW_COLORS.* = self.color;
    const flipped_dead = if (self.down) w4.BLIT_FLIP_Y else 0;
    w4.blit(&zoop_art, self.x, self.y, self.width, self.height, w4.BLIT_2BPP | flipped_dead);

    // show yurm text for at most 1/2 second, blinking at weird rate
    if (self.yurm_anim_time + 30 > frame and frame & 0b10100 > 0 and self.yurm_anim_time > 0) {
        w4.DRAW_COLORS.* = self.text_color;
        w4.text("yurm, pollin", self.x - 35, self.y - 13);
    }

    if (self.revive_anim_time + 15 > frame and self.revive_anim_time > 0) {
        w4.DRAW_COLORS.* = self.text_color;
        const radius: i32 = @intCast((15 - (frame - self.revive_anim_time)) * 2);
        const mx = self.x + @divTrunc(self.width, 2) - radius;
        const my = self.y + @divTrunc(self.height, 2) - radius;
        w4.oval(mx, my, radius * 2, radius * 2);
    }
}

pub fn show_score(self: *Self, position: i32) void {
    w4.DRAW_COLORS.* = self.text_color;
    if (self.down) {
        w4.text("Bees down!", 10, position);
    } else {
        const len = std.fmt.formatIntBuf(
            self.score_display[7..],
            self.pollin,
            10,
            .lower,
            .{},
        ) + 7;
        w4.text(self.score_display[0..len], 10, position);
    }
}

// zoop_art
const zoop_art = [44]u8{ 0x00, 0x51, 0x0a, 0x28, 0x01, 0xf7, 0x42, 0x20, 0x05, 0x55, 0x55, 0x55, 0x07, 0xae, 0xbf, 0xfd, 0x07, 0xae, 0xb7, 0xdd, 0xa7, 0xae, 0xbf, 0xfd, 0xa7, 0xae, 0xb7, 0xdd, 0x07, 0xae, 0xb5, 0x5d, 0x07, 0xae, 0xbf, 0xfd, 0x05, 0x55, 0x55, 0x55, 0x00, 0x14, 0x05, 0x00 };

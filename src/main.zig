const std = @import("std");
const w4 = @import("wasm4.zig");

const Sound = @import("Sound.zig");
const Song = @import("Song.zig");
const Controller = @import("Controller.zig");
const MainMenu = @import("MainMenu.zig");

const Zoop = @import("Zoopzoop.zig");
const Flower = @import("Flower.zig");
const Dick = @import("Dick.zig");

// set the starting position of our zoops
var zoops = [4]Zoop{
    .{
        .x = 10,
        .y = 10,
        .color = 0x1230,
        .text_color = 0x12,
    },
    .{
        .x = 134,
        .y = 10,
        .color = 0x1430,
        .text_color = 0x14,
    },
    .{
        .x = 10,
        .y = 139,
        .color = 0x2430,
        .text_color = 0x24,
    },
    .{
        .x = 134,
        .y = 139,
        .color = 0x1320,
        .text_color = 0x13,
    },
};
var active_zoops: u4 = 1;

// make a buffer of 640 flowers, we will only show
// up to `active_flowers` flowers
var flowers = [1]Flower{.{}} ** 640;
var active_flowers: usize = 4;

// high scores are saved globally
var high_score: packed struct {
    team: u32 = 0,
    solo: u16 = 0,
} = .{};
const save_size = @sizeOf(@TypeOf(high_score));
const save_ptr = @ptrCast([*]u8, &high_score);

// dick dastardly duck
var dick = Dick{};

// global random and time keeping (by frames)
var prng = std.rand.DefaultPrng.init(7658); //
export var rng: std.rand.Random = undefined;
export var frame: u32 = 0;

// give active flowers random positions and make them live!
fn randomize_flowers() void {
    for (flowers[0..active_flowers]) |*f| {
        f.x = rng.intRangeLessThan(i32, 0, 160 - Flower.width);
        f.y = rng.intRangeLessThan(i32, 0, 160 - Flower.height);
        f.withered = false;
    }
}

// if all flowers withered
fn check_all_flowers() bool {
    for (flowers[0..active_flowers]) |f| {
        if (f.withered == false) {
            return false;
        }
    }

    return true;
}

// if all bees downed
fn check_all_bees_down() bool {
    for (zoops[0..active_zoops]) |zoop| {
        if (zoop.down == false)
            return false;
    }

    return true;
}

fn total_pollins() u32 {
    var total: u32 = 0;
    for (zoops[0..active_zoops]) |zoop| {
        total += zoop.pollin;
    }

    return total;
}

// any player pressed the x button
fn any_pressed_x() bool {
    for (zoops[0..active_zoops]) |zoop| {
        if (zoop.controller.released.x) {
            return true;
        }
    }
    return false;
}

// set most of the game objects to starting state
fn reset() void {
    active_flowers = 4;
    zoops[0].x = 10;
    zoops[0].y = 10;

    zoops[1].x = 134;
    zoops[1].y = 10;

    zoops[2].x = 10;
    zoops[2].y = 139;

    zoops[3].x = 134;
    zoops[3].y = 139;

    for (zoops) |*zoop| {
        zoop.down = false;
        zoop.pollin = 0;
        zoop.yurm_anim_time = 0;
    }

    active_zoops = 1;

    dick.x = 56;
    dick.y = 56;

    randomize_flowers();

    _ = w4.diskw(save_ptr, save_size);
}

var in_main_menu: bool = true;

const pallet = [4]u32{
    0x00E8D6D9,
    0x006FA5B3,
    0x002D5B78,
    0x007A005A,
};

// only runs once at the start, setup first 4 flowers and colors.
export fn start() void {
    for (w4.PALETTE) |*p, n| {
        p.* = pallet[n];
    }

    rng = prng.random();

    randomize_flowers();
    const read = w4.diskr(save_ptr, save_size);
    if (read < save_size) {
        w4.trace("Failed to read full save data");
    }
}

const gamepads = [4]*const u8{
    w4.GAMEPAD1,
    w4.GAMEPAD2,
    w4.GAMEPAD3,
    w4.GAMEPAD4,
};

var last_pollin_collect_frame: u32 = 0;
var collect_pollin_sound = Sound{
    .freq = .{
        .start = 440,
    },

    .adsr = .{
        //.attack = 5,
        .release = 10,
    },
    .channel = .Pulse2,

    .volume = 10,
};

const dick_hit_sound = Sound{
    .freq = .{
        .start = 220,
        .end = 50,
    },
    .adsr = .{
        .attack = 15,
        .sustain = 15,
        .release = 20,
    },

    .channel = .Noise,
    .volume = 50,
};

const hunny_bee = Song.compile_roll(
    \\E - E - E - . | D - E . G  E . . | D E - E - E - . | D - E - F E | - D . E - E - E - . D - | E . G E . . D | E - E - E - . D - | E - F E - D | .
, 15);
const drums_roll = Song.compile_roll(
//\\C5 - - - - - - . | D5# - - - - - - . | D5 - - - - - - . | C5 - - - - - - . | B - - . B - - . | C5 - - . C5 - - . |
    \\E - - D C - . C - A3 | . . C - . C D . E - D C - . C - A3 | C - C - . D . . . . .
, 15);
var song = Song.init(&hunny_bee, .Triangle, 0, 40);
var drums = Song.init(&drums_roll, .Pulse2, 2, 15);

export fn update() void {
    if (!song.update())
        song.reset();
    //if (!drums.update())
    //drums.reset();

    if (active_zoops < 4) {
        for (gamepads) |gamepad, n| {
            if (gamepad.* > 0) {
                active_zoops = std.math.max(active_zoops, @intCast(u4, n + 1));
            }
        }
    }

    for (zoops[0..active_zoops]) |*zoop, n| {
        zoop.controller.update(gamepads[n]);
    }

    if (in_main_menu) {
        MainMenu.display(active_zoops, high_score.team, high_score.solo);
        if (any_pressed_x()) {
            in_main_menu = false;
        }
        return;
    }

    // Show pollin count
    for (zoops[0..active_zoops]) |*zoop, n| {
        zoop.show_score(10 + @intCast(i32, n) * 9);
    }

    for (zoops[0..active_zoops]) |*zoop| {
        // move and draw zoops
        zoop.update();
        if (dick.collides(zoop.*)) {
            if (!zoop.down) {
                dick_hit_sound.play();
            }

            zoop.down = true;
        }
    }

    // move and draw dick dastardly duck
    dick.update();

    if (check_all_bees_down()) {
        w4.text("All down!", 80 - 32, 80);

        const total = total_pollins();
        high_score.team = std.math.max(total, high_score.team);
        var totalString: [10]u8 = "Total:    ".*;
        const len = std.fmt.formatIntBuf(totalString[6..], total, 10, .lower, .{}) + 6;

        w4.text(totalString[0..len], 80 - @intCast(i32, len * 4), 89);

        if (any_pressed_x()) {
            in_main_menu = true;
            reset();
            return;
        }
    }

    // wither and draw flowers
    w4.DRAW_COLORS.* = 0x02;
    for (flowers[0..active_flowers]) |*f| {
        if (f.withered == false) {
            for (zoops[0..active_zoops]) |*zoop| {
                if (f.collides(zoop.*)) {
                    const in_time: bool = last_pollin_collect_frame + 20 > frame;
                    const valid: bool = last_pollin_collect_frame != 0;
                    const max_combo: bool = collect_pollin_sound.freq.start < 3520;
                    if (in_time and valid and max_combo) {
                        collect_pollin_sound.freq.start *= 2;
                    } else {
                        collect_pollin_sound.freq.start = 440;
                    }

                    last_pollin_collect_frame = frame;
                    zoop.yurm_anim_time = frame;
                    f.withered = true;
                    zoop.pollin += 1;
                    collect_pollin_sound.play();
                    high_score.solo = std.math.max(zoop.pollin, high_score.solo);
                    break;
                }
            }
        }

        f.update();
    }

    // check flowers are withered, revives zoops
    if (check_all_flowers()) {
        active_flowers = std.math.min(flowers.len, active_flowers + 1);
        randomize_flowers();
        for (zoops[0..active_zoops]) |*zoop| {
            if (zoop.down) {
                zoop.revive_anim_time = frame;
            }
            zoop.down = false;
        }
    }

    frame += 1;
}

const tone = @import("wasm4.zig").tone;
const std = @import("std");
const Self = @This();

pub const Channel = enum(u2) {
    Pulse1 = 0,
    Pulse2 = 1,
    Triangle = 2,
    Noise = 3,
};

freq: packed struct {
    start: u16,
    end: u16 = 0,
},

adsr: packed struct {
    sustain: u8 = 0,
    release: u8 = 4,
    decay: u8 = 0,
    attack: u8 = 0,
} = .{},

volume: u8 = 75,

channel: Channel = .Triangle,
mode: u8 = 0,

pub fn play(self: Self) void {
    const freq: u32 = @bitCast(self.freq);
    const adsr: u32 = @bitCast(self.adsr);
    const flags = @intFromEnum(self.channel) | self.mode;

    tone(freq, adsr, self.volume, flags);
}

pub fn play_channel(self: Self, channel: Channel) void {
    const freq: u32 = @bitCast(self.freq);
    const adsr: u32 = @bitCast(self.adsr);

    tone(freq, adsr, self.volume, @intFromEnum(channel));
}

pub fn length(self: Self) u16 {
    return self.adsr.sustain + self.adsr.attack + self.adsr.decay;
}

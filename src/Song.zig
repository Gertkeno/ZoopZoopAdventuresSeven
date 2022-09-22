const w4 = @import("wasm4.zig");
const std = @import("std");

const Channel = @import("Sound.zig").Channel;

const Song = @This();
const String = []const u8;

const freq1 = [_]u16{ 33, 34, 37, 39, 41, 43, 46, 49, 52, 55, 58, 61 };
fn note_to_freq(note: String) u16 {
    var index: usize = switch (std.ascii.toUpper(note[0])) {
        'C' => 0,
        'D' => 2,
        'E' => 4,
        'F' => 5,
        'G' => 7,
        'A' => 9,
        'B' => 11,
        else => unreachable,
    };
    var octive: u4 = 4;

    for (note[1..]) |n| {
        if (n == '#') {
            index += 1;
        } else if (n >= '0' and n <= '9') {
            octive = @truncate(u4, n - '0');
        }
    }

    return freq1[index] << (octive - 1);
}

test "Note parser" {
    try std.testing.expectEqual(@as(u16, 440), note_to_freq("A4"));
    try std.testing.expectEqual(@as(u16, 464), note_to_freq("A#"));
    try std.testing.expectEqual(@as(u16, 92), note_to_freq("F#2"));
}

fn compile_roll_size(comptime input: String) usize {
    @setEvalBranchQuota(99999);
    var length: usize = 0;

    var iterator = std.mem.tokenize(u8, input, &std.ascii.spaces);
    var newSilence = false;
    while (iterator.next()) |obj| {
        const i = obj[0];
        if (i == '.') {
            if (newSilence) {
                length += 1;
                newSilence = false;
            }
        } else if (!(i == '-' or i == '|')) {
            length += 1;
            newSilence = true;
        }
    }

    return length;
}

const Note = struct {
    const release: u16 = 6;
    freq: u16,
    len: u16,

    pub fn play(self: @This(), channel: Channel, mode: u8, volume: ?u8) void {
        if (self.freq != 0) {
            const len = (self.len - release) | (release << 8);
            w4.tone(self.freq, len, volume orelse 60, @enumToInt(channel) | (mode * 4));
        }
    }
};

/// translating bpm to step (FPS / (bpm / 60))
pub fn compile_roll(comptime input: String, step: usize) [compile_roll_size(input)]Note {
    var iterator = std.mem.tokenize(u8, input, &std.ascii.spaces);
    var length = compile_roll_size(input);

    var output: [length]Note = [1]Note{.{ .freq = 440, .len = 0 }} ** length;
    var oi: usize = 0;

    while (iterator.next()) |obj| {
        if (obj[0] == '|') {
            //
        } else if (obj[0] == '.') {
            if (output[oi - 1].freq == 0) {
                output[oi - 1].len += step;
            } else {
                output[oi].freq = 0;
                output[oi].len = step;
                oi += 1;
            }
        } else if (obj[0] == '-') {
            output[oi - 1].len += step;
        } else {
            const freq = note_to_freq(obj);
            output[oi].freq = freq;
            output[oi].len = step;
            oi += 1;
        }
    }

    return output;
}

test "Piano roll compiler" {
    const roll = comptime compile_roll("A - . E C - . .", 12);
    try std.testing.expectEqual(@as(usize, 5), roll.len);
    try std.testing.expectEqual(@as(u16, 440), roll[0].freq);
    try std.testing.expectEqual(@as(u16, 12), roll[1].len);
}

notes: []const Note,
channel: Channel,
mode: u8,
volume: u8,

index: usize = 0,
frame_count: usize = 0,
next_len: usize = 0,

pub fn init(input: []const Note, channel: Channel, mode: ?u8, volume: ?u8) Song {
    return Song{
        .notes = input,
        .channel = channel,
        .mode = mode orelse 0,
        .volume = volume orelse 60,
    };
}

pub fn update(self: *Song) bool {
    self.frame_count += 1;
    if (self.frame_count > self.next_len) {
        if (self.index < self.notes.len) {
            const note = self.notes[self.index];
            note.play(self.channel, self.mode, self.volume);

            self.index += 1;
            self.next_len += note.len;
        }

        return self.frame_count < self.next_len;
    }

    return true;
}

pub fn reset(self: *Song) void {
    self.index = 0;
    self.frame_count = 0;
    self.next_len = 0;
}

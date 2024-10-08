const std = @import("std");
const PA = @cImport({
    @cInclude("portaudio.h");
});
const AudioStream = @import("./AudioStream.zig").AudioStream;
const PaError = @import("./PaError.zig");
pub const SampleFormat = @import("./SampleFormat.zig").SampleFormat;
pub const StreamOptions = @import("./StreamOptions.zig").StreamOptions;

pub const Audio = struct {
    const Self = @This();
    _allocator: std.mem.Allocator,
    _device: ?PA.PaDeviceIndex = undefined,

    pub fn init(allocator: std.mem.Allocator) !Self {
        try PaError.handle(PA.Pa_Initialize());
        errdefer PA.Pa_Terminate();
        return .{ ._allocator = allocator };
    }

    pub fn getDefaultDevice(_: *const Self) !PA.PaDeviceIndex {
        const d = PA.Pa_GetDefaultOutputDevice();
        if (d == PA.paNoDevice) {
            return error.NoDevicesFound;
        }
        return d;
    }

    pub fn createStream(self: *const Self, comptime format: SampleFormat, options: StreamOptions) !*AudioStream(format) {
        return AudioStream(format).init(self._allocator, options);
    }

    pub fn sleep(_: *const Self, ms: c_long) void {
        PA.Pa_Sleep(ms);
    }

    pub fn terminate(_: *const Self) void {
        PaError.handle(PA.Pa_Terminate()) catch {};
    }
};

test "example" {
    const Sine = struct {
        var phase: f32 = 0;
        pub fn render(_: []const i16, output: []i16) void {
            for (0..output.len) |i| {
                phase += 0.025;
                if (phase > 1) {
                    phase -= 1;
                }
                const x: i16 = @intFromFloat(@sin(phase * 360.0 * std.math.pi / 180.0) * 3000);
                output[i] = x;
            }
        }
    };

    const audio = try Audio.init(std.testing.allocator);
    defer audio.terminate();

    const device = try audio.getDefaultDevice();
    const opts: StreamOptions = .{
        .device = device,
        .sample_rate = 44100,
        .channels = 1,
        .bit_depth = SampleFormat.i16,
    };
    const stream = try audio.createStream(SampleFormat.i16, opts);
    defer stream.close();

    try stream.start(Sine.render);
    audio.sleep(1000);
    try stream.stop();
}

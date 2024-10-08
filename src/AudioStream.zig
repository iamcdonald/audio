const std = @import("std");
const PA = @cImport({
    @cInclude("portaudio.h");
});
const PaError = @import("./PaError.zig");
const SampleFormat = @import("./SampleFormat.zig");
const CallbackWrapper = @import("./CallbackWrapper.zig").CallbackWrapper;
const StreamOptions = @import("./StreamOptions.zig").StreamOptions;

const AudioStreamError = error{OhNo};

pub fn AudioStream(format: SampleFormat.SampleFormat) type {
    const sample_format = SampleFormat.toPA(format);
    const SampleFormatType = SampleFormat.typeFromPA(sample_format);
    const Callback = CallbackWrapper(SampleFormatType);
    return struct {
        const Self = @This();
        _allocator: std.mem.Allocator,
        _options: StreamOptions,
        _stream: *PA.PaStream,
        _active: bool = false,

        pub fn init(allocator: std.mem.Allocator, options: StreamOptions) !*Self {
            const ptr = try allocator.create(AudioStream(format));
            errdefer allocator.destroy(ptr);
            ptr.* = .{
                ._allocator = allocator,
                ._options = options,
                ._stream = undefined,
            };
            return ptr;
        }

        fn getStreamParams(self: *Self) PA.PaStreamParameters {
            return .{
                .device = self._options.device,
                .channelCount = self._options.channels,
                .sampleFormat = sample_format,
                .suggestedLatency = PA.Pa_GetDeviceInfo(self._options.device).*.defaultLowOutputLatency,
                .hostApiSpecificStreamInfo = null,
            };
        }

        pub fn start(self: *Self, callback: Callback.TypeExternal) !void {
            if (self._active) {
                return error.AlreadyStarted;
            }

            const buffer_size = b_s: {
                if (self._options.buffer_size) |val| {
                    break :b_s @as(c_ulong, val);
                } else {
                    break :b_s PA.paFramesPerBufferUnspecified;
                }
            };

            const wrappedCallback = Callback.Wrapper.build(callback);
            try PaError.handle(
                PA.Pa_OpenStream(
                    @ptrCast(&self._stream),
                    null,
                    &self.getStreamParams(),
                    @as(f64, self._options.sample_rate),
                    buffer_size,
                    PA.paClipOff,
                    wrappedCallback,
                    undefined,
                ),
            );
            try PaError.handle(PA.Pa_StartStream(self._stream));
            self._active = true;
        }

        pub fn stop(self: *Self) !void {
            if (!self._active) {
                return error.NotStarted;
            }
            try PaError.handle(PA.Pa_StopStream(self._stream));
        }

        pub fn close(self: *const Self) void {
            defer self._allocator.destroy(self);
            PaError.handle(PA.Pa_CloseStream(self._stream)) catch {};
        }
    };
}

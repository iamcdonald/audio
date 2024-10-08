const PA = @cImport({
    @cInclude("portaudio.h");
});
const SampleFormat = @import("./SampleFormat.zig").SampleFormat;

pub const StreamOptions = struct {
    device: PA.PaDeviceIndex,
    channels: u8,
    sample_rate: f32,
    bit_depth: SampleFormat,
    buffer_size: ?u32 = undefined,
};

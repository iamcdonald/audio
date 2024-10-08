const PA = @cImport({
    @cInclude("portaudio.h");
});

pub const SampleFormat = enum {
    u8,
    i8,
    i16,
    i24,
    i32,
    f32,
};

pub fn toPA(format: SampleFormat) @TypeOf(PA.paUInt8) {
    return switch (format) {
        SampleFormat.u8 => PA.paUInt8,
        SampleFormat.i8 => PA.paInt8,
        SampleFormat.i16 => PA.paInt16,
        SampleFormat.i24 => PA.paInt24,
        SampleFormat.i32 => PA.paInt32,
        SampleFormat.f32 => PA.paFloat32,
    };
}

pub fn typeFromPA(format: @TypeOf(PA.paUInt8)) type {
    return switch (format) {
        PA.paUInt8 => u8,
        PA.paInt8 => i8,
        PA.paInt16 => i16,
        PA.paInt24 => i24,
        PA.paInt32 => i32,
        PA.paFloat32 => f32,
        else => error.InvalidFormat,
    };
}

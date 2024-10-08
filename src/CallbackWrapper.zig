const std = @import("std");
const PA = @cImport({
    @cInclude("portaudio.h");
});

const CallbackMeta = struct { TypeExternal: type, TypeInternal: type, Wrapper: type };

pub fn CallbackWrapper(T: type) CallbackMeta {
    const TypeExternal = *const fn (input: []const T, output: []T) void;
    const TypePA = *const fn (
        input: ?*const anyopaque,
        output: ?*anyopaque,
        frames_per_buffer: c_ulong,
        time_info: [*c]const PA.PaStreamCallbackTimeInfo,
        flags: PA.PaStreamCallbackFlags,
        ctx: ?*anyopaque,
    ) callconv(.C) c_int;

    const Wrapper = struct {
        pub fn build(callback: TypeExternal) TypePA {
            const Closure = struct {
                var cb: TypeExternal = undefined;
                pub fn exec(
                    input: ?*const anyopaque,
                    output: ?*anyopaque,
                    frames_per_buffer: c_ulong,
                    _: [*c]const PA.PaStreamCallbackTimeInfo,
                    _: PA.PaStreamCallbackFlags,
                    _: ?*anyopaque,
                ) callconv(.C) c_int {
                    const len: usize = @intCast(frames_per_buffer);
                    const i = in: {
                        if (input) |input_ptr| {
                            const i: [*]const T = @alignCast(@ptrCast(input_ptr));
                            break :in i[0..len];
                        } else {
                            const i = [0]T{};
                            break :in i[0..];
                        }
                    };
                    const o = in: {
                        if (output) |output_ptr| {
                            const o: [*]T = @alignCast(@ptrCast(output_ptr));
                            break :in o[0..len];
                        } else {
                            var o = [0]T{};
                            break :in o[0..];
                        }
                    };
                    cb(i, o);
                    return 0;
                }
            };
            Closure.cb = callback;
            return &Closure.exec;
        }
    };
    return .{ .TypeExternal = TypeExternal, .TypeInternal = TypePA, .Wrapper = Wrapper };
}

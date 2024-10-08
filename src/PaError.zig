const PA = @cImport({
    @cInclude("portaudio.h");
});

pub fn handle(err: PA.PaError) !void {
    if (err != PA.paNoError) {
        return error.PAError;
    }
}

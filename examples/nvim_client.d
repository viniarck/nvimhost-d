void main() {
    import std.stdio;
    import nvimhost.api : NvimAPI;
    auto nvim = NvimAPI();
    nvim.enableLog();

    // Calling a simple command on Neovim
    nvim.command("echomsg 'hello world!'");

    // Getting lines from current buffer
    auto currentBufferLines = nvim.bufferGetLines(nvim.getCurrentBuf(), 0, -1, true);
    writeln("# of lines on current buffer: ", currentBufferLines.length);

    // Iterating over loaded buffers
    auto buffers = nvim.vimGetBuffers();
    foreach (buffer; buffers) {
        writeln("buffer #", buffer);
    }

    // Checking if a variable exists
    if (nvim.exists("g:someRandomCounter")) {
        // convert to int
        auto someRandomCounter = nvim.getVarAs!(int)("g:someRandomCounter");
    }
}

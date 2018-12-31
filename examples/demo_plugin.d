import nvimhost.plugin;
import nvimhost.api;

struct DemoPlugin {

    NvimAPI nvim;

    this(ref NvimAPI nvim) {
        this.nvim = nvim;
    }

    // sync function with one argument
    @NvimFunc("Greet")
    string greet(string name) {
        return "Hello " ~ name;
    }

    // sync function with multiple arguments
    @NvimFunc("SumBeginToEnd")
    int sumBeginToEnd(int begin, int end) {
        import std.range;
        import std.algorithm.iteration;
        import std.stdio;

        return cast(int) iota(begin, end).sum();
    }

    // sync function calling async (non blocking) nvim functions
    @NvimFunc("SetVarValueSync")
    int setVarValue(int i) {
        import std.conv;

        nvim.commandAsync("let g:test_var_value=" ~ i.to!string);
        return i;
    }

    // async function calling both async and sync nvim functions
    @NvimFunc("SetVarValueAsync", Async)
    void setVarValueAsync(int i) {
        import std.conv;

        nvim.commandAsync("let g:testasync_var_value=" ~ i.to!string);
        nvim.command("echomsg 'hello world sync!'");
    }

}

void main() {

    // make sure you source this .vim file in neovim, since this will bootstrap
    // the binary and register the plugin
    auto pluginDstFile = "~/.config/nvim/settings/demo-plugin.vim";
    // template instantiate DemoPlugin
    auto plugin = NvimPlugin!(DemoPlugin)("demo-plugin", pluginDstFile);
    // keep it running
    scope (exit) {
        plugin.keepRunning();
    }
}

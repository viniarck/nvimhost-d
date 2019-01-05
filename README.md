## nvimhost-d

Neovim (nvim) host plugin provider and API client library written in [D](https://www.dlang.org).

## Docs

The following snippets show how you can use this library, check out the [exaples](./examples) for more information:

### Plugin snippet demo

```D
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
```

### API client snippet demo

```D
void main() {
    import std.stdio;
    import nvimhost.api : NvimAPI;
    auto nvim = NvimAPI();
    nvim.enableLog();

    // Calling a simple command on Neovim
    nvim.command("echomsg 'hello world!'");

    // Iterating over loaded buffers
    auto buffers = nvim.vimGetBuffers();
    foreach (buffer; buffers) {
        writeln("buffer #", buffer);
    }
}
```

## How to install

- Fetch it using `dub`, and use it as a library in your source code by importing the `nvimhost` package:

```
dub fetch nvimhost
dub build --build=release
```

## Testing

### Unit tests

```
dub test
```

### System tests

```
python -m pytest system_tests
```

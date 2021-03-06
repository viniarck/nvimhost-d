[![pipeline status](https://gitlab.com/viniarck/nvimhost-d/badges/master/pipeline.svg)](https://gitlab.com/viniarck/nvimhost-d/commits/master)
[![DUB Package](https://img.shields.io/dub/v/nvimhost.svg)](https://code.dlang.org/packages/nvimhost)

## nvimhost-d

Neovim (nvim) host plugin provider and API client library in [D](https://www.dlang.org).

![nvimhostd-logo](https://lh3.googleusercontent.com/JivbI2Qu3EtvQpl9pLNvn9jKTbv6i7Vmt313Ef0pKqWBf_nVofeYat9EArQ7WKKmYhGiHQvIAenre0yrBrlgZEq9xLcT754ZHCLxlZFPzheTn06WpkPRzxkbkRztQlPGYpF-aZzjglOhR_-3vMKHlnNlnt2Znb25Im0YRnrMOfD1hHX1sSj0WFGf8QW2oZ7-d3U4RdVEaOonigBzndNsD_sa9pUP2rrW38N3yZ0YB8L47x-lMoEsD6VBmyBjfxFG8GCz0WRW4qqS6p-P8yrOYI2ZksrQdHbqT3vC8-FNwWWgRfYvkP5Q_MPK-c2SdeaRR8vkbUSKw1ChmBcRXa8crDb93vYoT9s-rSb4y76n1-cXAKUIBGcueUglmkZ-5X-wQo9Ro9doDBjwBS4aegd9NeaCfguRkfBSc9f4MCQplpxzt-5p_qPQwdxbuOuHc1mT3HrcIiNZiOy15_PWEwWb4r0gRJoH0Yl63EAK1IiR4DF3lktC4yMuSgNWZ2ai_U4LQUJEJCPdtuET2AcVUC5KQmPLOrGU40D11R7WlRkBurDRykL0Q2RFsFDeE3ayMusIA7zPL-ypZ55bRCKNwwU0uI1Z2smdvHtmDVfpm0eppYMP6bd4QV5J1XUOqMC9LD1Pktv4XDsTlvre4CYMjPfwubs=w600-h180-no)

## Docs

The following snippets show how you can use this library, check out the [examples](./examples) for more information. This GIF shows the `demo-plugin` below in action:

![screencast](https://s8.gifyu.com/images/nvimhostd97b2cfe96c3f9f1a.gif)

## Goals

- Provide a library for high-performance plugins (it takes between 2-4ms on average via msgpack RPC to call a function).
- Provide an API for other projects to integrate with nvim.

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

You can find the code documentation generated by the dub registry [here](https://nvimhost.dpldocs.info/nvimhost.html).

## How to install and build

- Fetch it using `dub`, and use it as a library in your source code by importing the `nvimhost` package:

```
dub fetch nvimhost
dub build nvimhost --build=release
```

For more information about building binaries, check out the [.gitlab-ci.yml file](./.gitlab-ci.yml)

## How to ship plugin binaries

Either:

- Your users compile the binary using `ldc2`/`dmd` or
- You pre-compile dynamically linked binaries for the platforms you want to target.

Based on the current build settings, the dynamic linked binary will depend on common C libraries such as `libc.so.6`, `libpthread.so.0`, and a few others, which are expected to be present on most Unix distributions, so it should run without any issues.

## Trying out linux x86_64 compiled binaries

If you want to try out the `demo-plugin`, I've pre-compiled the binary for linux x86_64:

- `curl -LO https://github.com/viniarck/nvimhost-d/releases/download/v1.1.1/demo-plugin`
- `chmod +x demo-plugin`
- `sudo mv demo-plugin /usr/local/bin` (or somewhere else in your PATH)
- `demo-plugin` (execute the plugin once in your shell to generate the manifest)
- In your ~/.config/nvim/init.vim file, `source ~/.config/nvim/settings/demo-plugin.vim`

From this point forward, all plugin functions will be available to be called from `nvim`

- Launch `nvim` and call native D functions from this plugin, for example, `:call Greet("D")`

## Testing

Both unit tests and system tests (end-to-end) testing with nvim have been automated in the CI.

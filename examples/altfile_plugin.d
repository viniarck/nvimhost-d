import nvimhost.plugin;
import nvimhost.api;

struct CppAltFile {
    import std.path : expandTilde;
    import std.algorithm : canFind;
    import std.range : split;
    import std.file : dirEntries, SpanMode;
    import std.string : indexOf;
    import std.path : dirSeparator;

    /**
    if you need to debug, import std exp logger and
    export NVIMHOST_LOG_FILE=/tmp/nvimhost_log.txt

    import std.experimental.logger;
    // after that you can call trace() functions
    */

    NvimAPI nvim;

    this(ref NvimAPI nvim) {
        this.nvim = nvim;
    }

    /**
    Calls findAlt and if found a file, open the file on current buffer, split,
    or new tab.
    */
    @NvimFunc("GoFindAlt", Async)
    void goFindAlt(string action) {
        auto cwd = nvim.commandOutput("echo getcwd()");
        auto fileName = nvim.commandOutput("echo expand('%:p')");
        auto foundFile = findAlt(fileName, cwd);

        if (foundFile.length) {
            switch (action) {
            case "vs":
                nvim.commandAsync("vs " ~ foundFile);
                break;
            case "sp":
                nvim.commandAsync("sp " ~ foundFile);
                break;
            case "tabe":
                nvim.commandAsync("tabe " ~ foundFile);
                break;
            default:
                nvim.commandAsync("e " ~ foundFile);
            }
        } else {
            nvim.commandAsync("echo 'Alternate file not found!'");
        }
    }

    /**
    Find alternate file for *.c* and *.h* files. Return empty string if not found.
    */
    @NvimFunc("FindAlt")
    string findAlt(string fileName, string dir = "", bool ignoreHiddenDirs = true) {

        dir = expandTilde(dir);
        fileName = expandTilde(fileName);
        auto fSplit = fileName.split(dirSeparator)[$ - 1].split(".");
        if (fSplit.length) {
            auto sufix = fSplit[$ - 1];

            string altExtension;
            if (canFind(sufix, "h")) {
                altExtension = ".c";
            } else if (canFind(sufix, "c")) {
                altExtension = ".h";
            } else {
                return "";
            }

            auto fName = fSplit[$ - 2] ~ altExtension;
            auto dirIter = dirEntries(dir, "*" ~ altExtension ~ "*", SpanMode.breadth, true);
            foreach (entry; dirIter) {
                if (ignoreHiddenDirs && entry.isDir && entry.name.indexOf(".") >= 0) {
                    continue;
                }
                if (entry.isFile && entry.name.indexOf(fName) >= 0) {
                    return entry.name;
                }
            }
        }
        return "";
    }

}

void main() {
    import std.stdio;

    auto pluginDstFile = "~/.config/nvim/settings/altfile.vim";
    auto plugin = NvimPlugin!(CppAltFile)("altfile-plugin", pluginDstFile);
    scope (exit) {
        plugin.keepRunning();
    }
}

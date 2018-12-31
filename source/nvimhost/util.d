module nvimhost.util;

/**
Get the name of the app directory
*/
string appDir() @safe {
    import std.file : mkdirRecurse, tempDir;
    import std.path : dirSeparator;

    auto dir = tempDir ~ dirSeparator ~ "nvimhostd";
    mkdirRecurse(dir);
    return dir;
}

/**
Gen a unique UnixSocket source addr, this was needed due current vibe-core
connectTCP implementation.
*/
string genSrcAddr(bool overwrite=true) {
    import std.uuid : randomUUID;
    import std.path : dirSeparator;
    import std.file : remove, exists;

    auto srcAddr = appDir() ~ dirSeparator ~ randomUUID().toString();
    if (overwrite && exists(srcAddr)) {
        remove(srcAddr);
    }
    return srcAddr;
}

module nvimhost.plugin;

enum Exec {
    // Synchronous execution
    Sync,
    // Asynchronous execution means that Nvim won't wait for a response.
    Async,
    // Asynchronous Thread, is same as Async except it spawns a new Thread for each call.
    AsyncThread
};

alias Sync = Exec.Sync;
alias Async = Exec.Async;
alias AsyncThread = Exec.AsyncThread;

/**
NvimFunc is synchronous by default.
*/
struct NvimFunc {
    string name;
    Exec exec = Sync;
}

/**
Host a D plugin, by template instanciating a Struct on Nvim. The main thread (NvimClient)
provides a socket to call Nvim API functions, and there's a second thread, which is
exclusively used for exchanging call messages between the Plugin functions, commands, and Nvim.
*/
struct NvimPlugin(Struct) {
    import nvimhost.client;
    import nvimhost.api;
    import std.stdio;
    import std.traits;
    import std.meta : ApplyLeft, Filter;
    import std.variant;
    import std.typecons;
    import std.socket;
    import std.experimental.logger;
    import core.thread;
    import std.concurrency : thisTid, Tid, send, receiveOnly;
    import std.conv;
    import std.uni : toLower;
    import vibe.core.net;
    import eventcore.driver : IOMode;
    import nvimhost.util;
    import std.path;

public:
    // Encapsulate Nvim API to facilitate for final consumers of this Class.
    auto nvim = NvimAPI();
    // Template consumer class.
    Struct stc;

private:

    // The client instance will run in the main thread.
    NvimClient c = void;

    // Nvim callback socket to handle rpcnotify and rpcrequest.
    TCPConnection conn;
    NetworkAddress netAddr;
    string srcAddr;
    immutable bufferSize = 4096;
    static ubyte[bufferSize] cbBuffer;

    // Neovim cb channel ID
    ulong chId;

    // Main thread id
    Tid mTid;
    // Current supported return types
    enum string[string] retTypes = [
            "string" : "string", "bool" : "bool", "int" : "int", "double" : "double", "string[]"
            : "string[]", "bool[]" : "bool[]", "int[]" : "int[]", "double[]"
            : "double[]", "void" : "int", "immutable(char)[]"
            : "immutable(char)[]", "immutable(char)[][]" : "immutable(char)[][]"
        ];

    static string retTypesToString() {
        string res;
        foreach (k, v; retTypes) {
            res ~= v ~ " ";
        }
        return res;
    }

    /**
    Thread responsible for receiving nvim requests and notifications.
    Both requests and notifications are handled immediately. This thread is exclusive
    for this client, messages might queue up in the buffer size for now.
    Messages can come out of order.
    */
    void cbThread() {
        import msgpack;
        import std.file;
        import std.uuid;

        srcAddr = genSrcAddr();
        auto netSrcAddr = NetworkAddress(new UnixAddress(srcAddr));

        auto unixAddr = new UnixAddress(c.nvimAddr);
        assert(c.nvimAddr != c.nvimAddr.init);
        netAddr = NetworkAddress(unixAddr);

        trace(c.logEnabled, "cbThread opening TCP connection");
        conn = connectTCP(netAddr, netSrcAddr);
        conn.keepAlive(true);
        trace(c.logEnabled, "cbThread connected");

        requestChannelId();
        tracef(c.logEnabled, "cbThread ready, chid %d", chId);
        mTid.send("connected");

        ubyte[] data;
        while (true) {
            // async conn
            data = rcvdCbSocket();
            if (data) {
                tracef(c.logEnabled, "%( %x%)", data);
                auto msg = c.inspectMsgKind(data);
                final switch (msg.kind) {
                case MsgKind.request:
                    tracef(c.logEnabled,"received request id %s, method %s, args %s",
                            msg.id, msg.method, msg.args);
                    try {
                        tracef(c.logEnabled, "msg args: %s", msg.args);
                        auto decoded = c.decodeMethod(msg.method);
                        if (decoded.type == MethodType.NvimFunc) {
                            auto ret = dispatchMethod(decoded.name, msg.args);
                            tracef(c.logEnabled, "ret: %s", ret);
                outer:
                            switch (ret.type.toString) {
                                static foreach (k, v; retTypes) {
                            case k:
                                    mixin(v ~ " t;");
                                    auto packed = pack(MsgKind.response,
                                            msg.id, null, ret.get!(typeof(t)));
                                    tracef(c.logEnabled, "replying with %(%x %)", packed);
                                    conn.write(packed);
                                    break outer;
                                }
                            default:
                                throw new Exception("This return type " ~ ret.type.toString
                                        ~ " is not supported. Plese, use any of these for now: "
                                        ~ retTypesToString);
                            }
                        }
                    } catch (Exception e) {
                        errorf(e.msg);
                        auto packed = pack(MsgKind.response, msg.id, e.msg, null);
                        conn.write(packed);
                    }
                    break;
                case MsgKind.response:
                    tracef(c.logEnabled,
                            "received response id %s, method %s, args %s",
                            msg.id, msg.method, msg.args);
                    break;
                case MsgKind.notify:
                    tracef(c.logEnabled,
                            "received notify, method %s, args %s", msg.method, msg.args);
                    auto decoded = c.decodeMethod(msg.method);
                    try {
                        if (decoded.type == MethodType.NvimFunc) {
                            auto ret = dispatchMethod(decoded.name, msg.args);
                        }
                    } catch (Exception e) {
                        errorf(e.msg);
                        c.call!(void)("nvim_err_writeln", e.msg);
                    }
                    // TODO implement option to spawn a new thread.
                    break;
                }
            }
        }
    }

    /**
    Runtime dispatch method from an RPC request/notify.
    */
    Variant dispatchMethod(string methodName, Variant[] args) {
        import std.traits : ReturnType, Parameters;
        tracef(c.logEnabled, "dispatchMethod methodName: %s args: %s", methodName, args);
        switch (methodName) {
            default:
                throw new Exception("Unknown function: " ~ methodName);
            static foreach (name; AllPluginFuncs!Struct) {
                static foreach (attr; __traits(getAttributes, __traits(getMember, Struct, name))) {
                    static if (is(typeof(attr) == NvimFunc)) {
                        case attr.name:
                        {
                            try {
                                Parameters!(mixin("Struct." ~ name)) tup;
                                if (tup.length != args.length) {
                                    enum errMsg = "Wrong number of function params. Expected: " ~ Parameters!(__traits(getMember, Struct, name)).stringof;
                                    throw new Exception(errMsg);
                                }
                                static foreach (i; 0 .. tup.length) {
                                    tup[i] = args[i].get!(typeof(tup[i]));
                                }
                                static if (ReturnType!(mixin("Struct." ~ name)).stringof !in retTypes) {
                                    import std.array;
                                    static assert(false, "This return type " ~ ReturnType!(mixin("Struct." ~ name)).stringof ~ " is not supported yet, please use any of these instead for now: " ~ NvimPlugin.retTypesToString());
                                }
                                static if (is(ReturnType!(mixin("Struct." ~ name)) == void)) {
                                    static if (attr.exec == Sync) {
                                       static assert(false, "Sync NvimFunc can't return void.");
                                    }
                                    mixin("stc." ~ name ~ "(tup); return Variant(0);");
                                } else {
                                    mixin("return Variant(stc." ~ name ~ "(tup));");
                                }
                            } catch(VariantException e) {
                                    enum errMsg = "Wrong function argument types. Expected: " ~ Parameters!(__traits(getMember, Struct, name)).stringof;
                                    errorf(errMsg ~ "." ~ e.msg ~ "." ~ "Variant args: %s", args);
                                    throw new Exception(errMsg);
                            }
                        }
                    }
                }
            }
        }
    }

    enum isPluginMethod(T, string name) = __traits(compiles, {
            static foreach (attr; __traits(getAttributes, __traits(getMember, T, name))) {
                static if (is(typeof(attr) == NvimFunc)) {
                    enum found = true;
                }
            }
            static if (found) {
                auto x = found;
            }
        });

    alias AllPluginFuncs(T) = Filter!(ApplyLeft!(isPluginMethod, T), __traits(allMembers, T));

    /**
    Async connection read
    */
    ubyte[] rcvdCbSocket() {
        size_t nBytes = bufferSize;
        ubyte[] data;
        do {
            nBytes = conn.read(cbBuffer, IOMode.once);
            tracef("Received nBytes %d", nBytes);
            data ~= cbBuffer[0 .. nBytes];
        }
        while (nBytes >= bufferSize);
        return data;
    }

    /**
    Identify the callback channel ID of this client.
    */
    ulong requestChannelId() {
        import msgpack;
        import std.string : format;

        if (!chId) {
            auto myT = tuple();
            auto s = Msg!(myT.Types)(MsgKind.request, 0, "nvim_get_api_info", myT);
            auto packed = pack(s);

            ubyte[] data;
            conn.write(packed, IOMode.once);
            data = rcvdCbSocket();

            auto unpacker = StreamingUnpacker(cast(ubyte[]) null);
            unpacker.feed(data);
            unpacker.execute();
            foreach (unpacked; unpacker.purge()) {
                if (unpacked.type == Value.Type.array) {
                    foreach (item; unpacked.via.array) {
                        // first element in this array has to be the chid
                        if (item.type == Value.Type.unsigned) {
                            chId = item.via.uinteger;
                            return chId;
                        }
                    }
                }
            }
            throw new Exception("nvim_get_api has changed.");
        }
        return chId;
    }

    void ensureDirCreated(string filePath) {
        import std.range;
        import std.file;
        import std.path;

        auto folderPath = filePath.expandTilde.split(dirSeparator)[0 .. $ - 1];
        mkdirRecurse(folderPath.join(dirSeparator));
    }

public:

    this(string pluginBinPath, string outManifestFilePath) {
        c = nvim.getClient();
        c.enableLog();
        c.connect();
        stc = Struct(nvim);

        ensureDirCreated(outManifestFilePath);
        genManifest!Struct(pluginBinPath, expandTilde(outManifestFilePath));

        mTid = thisTid;
        auto tcb = new Thread(&cbThread);
        tcb.isDaemon(true);
        tcb.start();

        trace(c.logEnabled, "Waiting for cbThread message");
        receiveOnly!string();
        trace(c.logEnabled, "Received cbThread message");

        immutable string loadedName = Struct.stringof.toLower;
        logf(c.logEnabled, "Setting g:" ~ loadedName ~ "_channel" ~ "=" ~ to!string(chId));
        c.call!(void)("nvim_command", "let g:" ~ loadedName ~ "_channel" ~ "=" ~ to!string(chId));
        trace(c.logEnabled, "Plugin " ~ loadedName ~ " is ready!");
    }

    ~this(){
        close();
    }

    /**
    Release resources.
    */
    void close() {
        import std.file : exists, remove;
        if (netAddr.family == AddressFamily.UNIX) {
            conn.close();
        }
        if (srcAddr.length && exists(srcAddr)) {
            remove(srcAddr);
        }
    }

    /**
    Used for keeping the main and callback daemonized thread open.
    You should only call keepRunning if you don't have an inifinite loop in your void main(), for example:

    void main(){
        auto p = new NvimPlugin!MyPluginClassHere;
        scope(exit) p.keepRunning();
    }
    */
    void keepRunning() {
        while (true) {
            Thread.sleep(60.seconds);
        }
    }

    /**
    Generate plugin manifest, the plugin hosted name is the class name lowered case.
    The binary path of the plugin application should be in your path. autoCmdPattern
    is used for registring an auto command for this plugin, by default, it doesn't
    restrict any pattern at all. As soon as the plugin is registered, all the functions
    and commands will be lazy loaded, and the binary will be executed as soon as your
    make a first call from Nvim.
    */
    void genManifest(Struct)(string binExecutable, string outputFile, string autoCmdPattern = "*") {
        import std.stdio : writeln, File;
        import std.string : format;
        import std.uni : toLower;
        import std.file;
        import std.path;

        immutable string loadedName = Struct.stringof.toLower;
        // 1 -> loadedName
        // 2 -> binExecutablePath
        // 3 -> autoCmdPattern
        auto manifestExpr = `
if exists('g:loaded_%1$s')
  finish
endif
let g:loaded_%1$s = 1

function! F%1$s(host)
  if executable('%2$s') != 1
    echoerr "Executable '%2$s' not found in PATH."
  endif

  let g:job_%1$s = jobstart(['%2$s'])

  " make sure the plugin host is ready and double check rpc channel id
  let g:%1$s_channel = 0
  for count in range(0, 100)
    if g:%1$s_channel != 0
      break
    endif
    sleep 1m
  endfor
  if g:%1$s_channel == 0
    echoerr "Failed to initialize %1$s"
  endif

  return g:%1$s_channel
endfunction

call remote#host#Register('%1$s', '%3$s', function('F%1$s'))`;

        auto registerHead = `
call remote#host#RegisterPlugin('%1$s', '%1$sPlugin', [`;
        auto registerFunc = `
\ {'type': 'function', 'name': '%1$s', 'sync': %2$d, 'opts': {}},`;
        immutable string registerTail = `
\ ])`;
        string[] lines;

        lines ~= manifestExpr.format(loadedName, binExecutable, autoCmdPattern);
        lines ~= registerHead.format(loadedName);

        static foreach (name; __traits(allMembers, Struct)) {
            static foreach (attr; __traits(getAttributes, __traits(getMember, Struct, name))) {
                static if (is(typeof(attr) == NvimFunc)) {
                    static if (attr.exec == Async) {
                        lines ~= registerFunc.format(attr.name, 0);
                    } else static if (attr.exec == Sync) {
                        lines ~= registerFunc.format(attr.name, 1);
                    } else static if (attr.exec == AsyncThread) {
                        static assert("AsyncThread is not supported yet.");
                    }
                }
            }
        }

        if (lines.length < 3) {
            throw new Exception("At least one decorated @NvimFunc is required.");
        }

        lines ~= registerTail;

        auto f = File(outputFile.expandTilde, "w");
        foreach (item; lines) {
            f.write(item);
        }
    }
}

module nvimhost.client;

alias Buffer = int;
alias Window = int;
alias Tabpage = int;
alias NullInt = int;

enum MsgPackNullValue = 0xc0;

enum NeoExtType {
    Buffer,
    Window,
    Tabpage
}

enum MsgKind {
    request = 0,
    response = 1,
    notify = 2,
}

struct Msg(T...) {
    import std.typecons;

    int kind;
    ulong id;
    string method;
    Tuple!(T) args;
}

struct MsgAsync(T...) {
    import std.typecons;

    int kind;
    string method;
    Tuple!(T) args;
}

struct MsgResponse(T) {
    int kind;
    ulong id;
    NullInt nullInt;
    T ret;
}

struct MsgVariant {
    import std.typecons;
    import std.variant;

    int kind;
    ulong id;
    string method;
    Variant[] args;
}

enum MethodType {NvimFunc};

struct MethodInfo {
    MethodType type;
    string name;
}

struct NvimClient {
    import std.stdio;
    import std.socket;
    import std.process : environment;
    import std.typecons;
    import core.time;
    import core.thread;
    import std.concurrency : thisTid, Tid, send, receiveOnly;
    import std.experimental.logger;
    import vibe.core.net;
    import eventcore.driver : IOMode;
    import nvimhost.util;

public:
    string nvimAddr;
    bool logEnabled;

private:
    // Client main async connection
    TCPConnection conn;
    NetworkAddress netAddr;
    string srcAddr;
    immutable bufferSize = 4096;
    static ubyte[bufferSize] buffer;

    /// Msgpack ID counter only used for synchronous messages.
    ulong msgId = 2;

    /**
    Replace nulls with a default value to facilitate unpacking.
    */
    void replaceNulls(ubyte[] array, ubyte newByte) {
        foreach (ref item; array) {
            if (item == MsgPackNullValue) {
                item = 0x0;
            }
        }
    }

    unittest {
        auto n = NvimClient();
        ubyte[] arr = [0, 1, 2, MsgPackNullValue, 3, MsgPackNullValue];
        n.replaceNulls(arr, 0);
        assert(arr == [0, 1, 2, 0, 3, 0]);
    }

    /**
    Convert ubytes arry to int
    */
    int uBytesToInt(ubyte[] arr) const {
        int value = 0;
        for (size_t i = 0; i < arr.length; ++i) {
            value += arr[i] << (8 * (arr.length - 1 - i));
        }
        return value;
    }

    unittest {
        auto n = NvimClient();
        assert(n.uBytesToInt([1, 0]) == 256);
        assert(n.uBytesToInt([1, 1, 0]) == 65792);
        assert(n.uBytesToInt([1]) == 1);
    }

    /**
    Make a generic RPC call to Nvim. If the struct is MsgAsync it's
    async, and the message is sent and no reply is ever received back (it's like
    fire and forget). If it's sync (Msg struct), then Nvim will send a reply.
    */
    auto callRPC(Ret = int, Struct)(Struct s) {
        import msgpack;
        import std.string : indexOf;

        // connect if not connected yet
        if (netAddr.family != AddressFamily.UNIX) {
            this.connect();
        }

        auto packed = pack(s);
        conn.write(packed, IOMode.once);
        static if (indexOf(Struct.stringof, "MsgAsync!") != -1) {
            tracef(logEnabled, "Sent async request data:\n%(%x %)", packed);
            return 0;
        } else {
            tracef(logEnabled, "Sending request %d: method: %s \n%(%x %)", s.id, s.method, packed);

            size_t nBytes = bufferSize;
            ubyte[] data;
            do {
                nBytes = conn.read(buffer, IOMode.once);
                tracef("Received nBytes %d", nBytes);
                data ~= buffer[0 .. nBytes];
            }
            while (nBytes >= bufferSize);

            tracef(logEnabled, "Received response (pre-unpack) :\n%(%x %)", data);
            replaceNulls(data, NullInt.init);

            auto unpacked = unpack!(MsgResponse!Ret)(data);
            tracef(logEnabled, "Received response (unpacked bytes replaced) %d:\n%(%x %)", unpacked.id, data);

            static if (Ret.stringof == "ExtValue[]") {
                if (unpacked.ret.length) {
                    int[] nums;
                    logf(logEnabled, "ExtType request %d:%s\n", unpacked.id, unpacked.ret);
                    foreach (item; unpacked.ret) {
                        if (item.data.length > 1) {
                            nums ~= uBytesToInt(item.data[1 .. $]);
                        } else {
                            nums ~= uBytesToInt(item.data);
                        }
                    }
                    return nums;
                }
            } else static if (Ret.stringof == "ExtValue") {
                auto item = unpacked.ret;
                int num;
                if (item.data.length > 1) {
                    num = uBytesToInt(item.data[1 .. $]);
                } else {
                    num = uBytesToInt(item.data);
                }
                return num;
            } else {
                return unpacked.ret;
            }
        }
        assert(0);
    }

        unittest {
        auto n = NvimClient();
        auto s = n.inspectMsgKind([0x94, 0x01, 0x01, MsgPackNullValue]);
        assert(s.id == 0x01 && s.kind == MsgKind.response);
        s = n.inspectMsgKind([0x94, 0x02, MsgPackNullValue]);
        assert(s.kind == MsgKind.notify);
        s = n.inspectMsgKind([0x94, 0x00, 0x02, MsgPackNullValue]);
        assert(s.id == 0x02 && s.kind == MsgKind.request);
        // 0x66 is the letter f
        s = n.inspectMsgKind([0x94, 0x00, 0x03, 0xa2, 0x66, 0x66, 0x90]);
        s = n.inspectMsgKind([0x94, 0x00, 0x03, 0xa2, 0x66, 0x66, 0x92, 0x1, 0xa1, 0x66]);
        assert(s.id == 0x03 && s.kind == MsgKind.request && s.method == "ff" && s.args[0] == 1 && s.args[1] == "f");
    }

public:

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
    Enable logging.
    */
    void enableLog() {
        if (environment.get("NVIMHOST_LOG")) {
           logEnabled = true;
        }
        // if this env var is not defined it'll log to stderr
        string logFile = environment.get("NVIMHOST_LOG_FILE");
        if (logFile) {
            logEnabled = true;
            sharedLog = new FileLogger(logFile);
        }
    }

    ~this(){
        close();
    }

    /**
    Decode Nvim request/notifications method strings names, which has this format:

    pluginName:function:functionName
    pluginName:command:commandName

    */
    MethodInfo decodeMethod(string methodName) {
        import std.array;
        auto res = methodName.split(":");
        if (res.length != 3) {
           throw new Exception("The methodName is supposed to match this regex .+:function|command:.+");
        }
        switch(res[1]) {
            case "function":
                return MethodInfo(MethodType.NvimFunc, res[2]);
            default:
               throw new Exception("Unsupported type received: " ~ res[1]);
        }
    }

    unittest {
        auto c = NvimClient();
        auto res = c.decodeMethod("pluginName:function:SomeFunction");
        assert(res.type == MethodType.NvimFunc && res.name == "SomeFunction");
    }

    /**
    Inspect the first two bytes of the serialized message to figure out message type of Nvim.
    */
    auto inspectMsgKind(ubyte[] arr) {
        import msgpack;
        import std.variant;

        if (arr.length < 3) {
            assert(false, "Truncated message received.");
        }

        auto unpacker = StreamingUnpacker(cast(ubyte[]) null);
        unpacker.feed(arr);
        unpacker.execute();

        int msgType = -1;
        int id;
        string method;
        auto myT = tuple();
        Variant[] varArgs;

        /**
        Recursively unpacks array lists.
        Nvim wraps funcs and cmd args via RPC in nested lists issue #1929
        */
        void unpackArray(ref Variant[] varArr, Value[] arr) {
            Variant arg;
            foreach (item; arr) {
                switch(item.type) {
                    // chances are for plugins cast(int) will be enough for most cases
                    case Value.Type.unsigned:
                        arg = cast(int) item.via.uinteger;
                        varArr ~= arg;
                        break;
                    case Value.Type.signed:
                        arg = cast(int) item.via.integer;
                        varArr ~= arg;
                        break;
                    case Value.Type.boolean:
                        arg = item.via.boolean;
                        varArr ~= arg;
                        break;
                    case Value.Type.raw:
                        arg = cast(string) item.via.raw;
                        varArr ~= arg;
                        break;
                    case Value.Type.floating:
                        arg = item.via.floating;
                        varArr ~= arg;
                        break;
                    case Value.Type.array:
                        tracef(logEnabled, "nested array");
                        unpackArray(varArr, item.via.array);
                        break;
                    default:
                        errorf("Nested type %s is not supported yet", item.type);
                        break;
                }
            }
        }

        foreach (unpacked; unpacker.purge()) {
            if (unpacked.type == Value.Type.unsigned) {
                if (unpacked.type == Value.Type.unsigned ) {
                    if (msgType == -1) {
                        msgType = cast(int) unpacked.via.uinteger;
                    } else {
                        id = cast(int) unpacked.via.uinteger;
                    }
                }
            } else if (unpacked.type == Value.Type.raw) {
                method = cast (string)unpacked.via.raw;
            } else if (unpacked.type == Value.Type.array) {
                unpackArray(varArgs, unpacked.via.array);
            } else if (unpacked.type == Value.Type.nil) {
                // incoming nulls don't matter.
                continue;
            } else {
                errorf("Type %s is not supported as a response param yet", unpacked.type);
            }
        }
        auto res = MsgVariant(msgType, id, method, varArgs);
        assert(msgType >= 0, "Couldn't parse message type.");
        assert(id >= 0, "Couldn't parse message id.");

        return res;
    }


    /**
    Asynchronous call returns immediatetly after serialializing the data over RPC.
    */
    auto callAsync(Ret, T...)(string cmd, T args) if (Ret.stringof == "void") {
        import std.traits;

        auto myT = tuple(args);
        auto msgAsync = MsgAsync!(myT.Types)(MsgKind.notify, cmd, myT);
        callRPC!(Ret)(msgAsync);
    }

    /**
    Synchronous call.
    */
    auto call(Ret = int, T...)(string cmd, T args) {
        import std.traits;

        auto myT = tuple(args);
        auto msg = Msg!(myT.Types)(MsgKind.request, ++msgId, cmd, myT);

        static if (Ret.stringof == "void") {
            auto res = callRPC!(int)(msg);
        } else {
            return callRPC!(Ret)(msg);
        }
    }

    /**
    Open an async TCP connection handler to Nvim using UnixAddress
    */
    void connect() {
        import std.path;
        import std.conv;
        import std.uuid;
        import std.file;
        this.nvimAddr = environment.get("NVIM_LISTEN_ADDRESS", "");
        if (nvimAddr == "") {
            throw new Exception("Couldn't get NVIM_LISTEN_ADDRESS, is nvim running?");
        }

        auto unixAddr = new UnixAddress(nvimAddr);
        netAddr = NetworkAddress(unixAddr);
        srcAddr = genSrcAddr();
        auto netSrcAddr = NetworkAddress(new UnixAddress(srcAddr));
        conn = connectTCP(netAddr, netSrcAddr);
        conn.keepAlive(true);
        tracef(logEnabled, "Main thread connected to nvim");
    }
}

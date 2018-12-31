module nvimhost.api;
import nvimhost.client;
import msgpack : ExtValue;
// Auto generated

alias Buffer = int;
alias Window = int;
alias Tabpage = int;

struct NvimAPI {

private:

    auto client = NvimClient();

public:

    NvimClient getClient() {
        return client;
    }

    void enableLog() {
        client.enableLog();
    }

    bool exists(string varName) {
        auto cmdOut = this.commandOutput("echo exists('" ~ varName ~ "')");
        if (cmdOut == "1") {
            return true;
        }
        return false;
    }

    auto getVarAs(T=string)(string varName) {
        import std.conv;
        auto cmdOut = this.commandOutput("echo " ~ varName);
        return cmdOut.to!(T);
    }

    void eval(string expr) {

        return client.call!(void)("nvim_eval", expr);

    }

    void evalAsync(string expr) {

        return client.callAsync!(void)("nvim_eval", expr);

    }

    int bufLineCount(Buffer buffer) {

        return client.call!(int)("nvim_buf_line_count", buffer);

    }

    string bufferGetLine(Buffer buffer, int index) {

        return client.call!(string)("buffer_get_line", buffer , index);

    }

    bool bufDetach(Buffer buffer) {

        return client.call!(bool)("nvim_buf_detach", buffer);

    }

    void bufferSetLine(Buffer buffer, int index, string line) {

        client.call!(void)("buffer_set_line", buffer , index , line);

    }

    void bufferSetLineAsync(Buffer buffer, int index, string line) {

        client.callAsync!(void)("buffer_set_line", buffer , index , line);

    }

    void bufferDelLine(Buffer buffer, int index) {

        client.call!(void)("buffer_del_line", buffer , index);

    }

    void bufferDelLineAsync(Buffer buffer, int index) {

        client.callAsync!(void)("buffer_del_line", buffer , index);

    }

    string[] bufferGetLineSlice(Buffer buffer, int start, int end, bool include_start, bool include_end) {

        return client.call!(string[])("buffer_get_line_slice", buffer , start , end , include_start , include_end);

    }

    string[] bufGetLines(Buffer buffer, int start, int end, bool strict_indexing) {

        return client.call!(string[])("nvim_buf_get_lines", buffer , start , end , strict_indexing);

    }

    void bufferSetLineSlice(Buffer buffer, int start, int end, bool include_start, bool include_end, string[] replacement) {

        client.call!(void)("buffer_set_line_slice", buffer , start , end , include_start , include_end , replacement);

    }

    void bufferSetLineSliceAsync(Buffer buffer, int start, int end, bool include_start, bool include_end, string[] replacement) {

        client.callAsync!(void)("buffer_set_line_slice", buffer , start , end , include_start , include_end , replacement);

    }

    void bufSetLines(Buffer buffer, int start, int end, bool strict_indexing, string[] replacement) {

        client.call!(void)("nvim_buf_set_lines", buffer , start , end , strict_indexing , replacement);

    }

    void bufSetLinesAsync(Buffer buffer, int start, int end, bool strict_indexing, string[] replacement) {

        client.callAsync!(void)("nvim_buf_set_lines", buffer , start , end , strict_indexing , replacement);

    }

    int bufGetChangedtick(Buffer buffer) {

        return client.call!(int)("nvim_buf_get_changedtick", buffer);

    }

    void bufDelVar(Buffer buffer, string name) {

        client.call!(void)("nvim_buf_del_var", buffer , name);

    }

    void bufDelVarAsync(Buffer buffer, string name) {

        client.callAsync!(void)("nvim_buf_del_var", buffer , name);

    }

    int bufGetNumber(Buffer buffer) {

        return client.call!(int)("nvim_buf_get_number", buffer);

    }

    string bufGetName(Buffer buffer) {

        return client.call!(string)("nvim_buf_get_name", buffer);

    }

    void bufSetName(Buffer buffer, string name) {

        client.call!(void)("nvim_buf_set_name", buffer , name);

    }

    void bufSetNameAsync(Buffer buffer, string name) {

        client.callAsync!(void)("nvim_buf_set_name", buffer , name);

    }

    bool bufIsValid(Buffer buffer) {

        return client.call!(bool)("nvim_buf_is_valid", buffer);

    }

    void bufferInsert(Buffer buffer, int lnum, string[] lines) {

        client.call!(void)("buffer_insert", buffer , lnum , lines);

    }

    void bufferInsertAsync(Buffer buffer, int lnum, string[] lines) {

        client.callAsync!(void)("buffer_insert", buffer , lnum , lines);

    }

    int[2] bufGetMark(Buffer buffer, string name) {

        return client.call!(int[2])("nvim_buf_get_mark", buffer , name);

    }

    int bufAddHighlight(Buffer buffer, int src_id, string hl_group, int line, int col_start, int col_end) {

        return client.call!(int)("nvim_buf_add_highlight", buffer , src_id , hl_group , line , col_start , col_end);

    }

    void bufClearHighlight(Buffer buffer, int src_id, int line_start, int line_end) {

        client.call!(void)("nvim_buf_clear_highlight", buffer , src_id , line_start , line_end);

    }

    void bufClearHighlightAsync(Buffer buffer, int src_id, int line_start, int line_end) {

        client.callAsync!(void)("nvim_buf_clear_highlight", buffer , src_id , line_start , line_end);

    }

    Window[] tabpageListWins(Tabpage tabpage) {

        return client.call!(ExtValue[])("nvim_tabpage_list_wins", tabpage);

    }

    void tabpageDelVar(Tabpage tabpage, string name) {

        client.call!(void)("nvim_tabpage_del_var", tabpage , name);

    }

    void tabpageDelVarAsync(Tabpage tabpage, string name) {

        client.callAsync!(void)("nvim_tabpage_del_var", tabpage , name);

    }

    Window tabpageGetWin(Tabpage tabpage) {

        return client.call!(ExtValue)("nvim_tabpage_get_win", tabpage);

    }

    int tabpageGetNumber(Tabpage tabpage) {

        return client.call!(int)("nvim_tabpage_get_number", tabpage);

    }

    bool tabpageIsValid(Tabpage tabpage) {

        return client.call!(bool)("nvim_tabpage_is_valid", tabpage);

    }

    void uiAttach(int width, int height, bool enable_rgb) {

        client.call!(void)("ui_attach", width , height , enable_rgb);

    }

    void uiAttachAsync(int width, int height, bool enable_rgb) {

        client.callAsync!(void)("ui_attach", width , height , enable_rgb);

    }

    void uiDetach() {

        client.call!(void)("nvim_ui_detach");

    }

    void uiDetachAsync() {

        client.callAsync!(void)("nvim_ui_detach");

    }

    void uiTryResize(int width, int height) {

        client.call!(void)("nvim_ui_try_resize", width , height);

    }

    void uiTryResizeAsync(int width, int height) {

        client.callAsync!(void)("nvim_ui_try_resize", width , height);

    }

    void command(string command) {

        client.call!(void)("nvim_command", command);

    }

    void commandAsync(string command) {

        client.callAsync!(void)("nvim_command", command);

    }

    void feedkeys(string keys, string mode, bool escape_csi) {

        client.call!(void)("nvim_feedkeys", keys , mode , escape_csi);

    }

    void feedkeysAsync(string keys, string mode, bool escape_csi) {

        client.callAsync!(void)("nvim_feedkeys", keys , mode , escape_csi);

    }

    int input(string keys) {

        return client.call!(int)("nvim_input", keys);

    }

    string replaceTermcodes(string str, bool from_part, bool do_lt, bool special) {

        return client.call!(string)("nvim_replace_termcodes", str , from_part , do_lt , special);

    }

    string commandOutput(string command) {

        return client.call!(string)("nvim_command_output", command);

    }

    int strwidth(string text) {

        return client.call!(int)("nvim_strwidth", text);

    }

    string[] listRuntimePaths() {

        return client.call!(string[])("nvim_list_runtime_paths");

    }

    void setCurrentDir(string dir) {

        client.call!(void)("nvim_set_current_dir", dir);

    }

    void setCurrentDirAsync(string dir) {

        client.callAsync!(void)("nvim_set_current_dir", dir);

    }

    string getCurrentLine() {

        return client.call!(string)("nvim_get_current_line");

    }

    void setCurrentLine(string line) {

        client.call!(void)("nvim_set_current_line", line);

    }

    void setCurrentLineAsync(string line) {

        client.callAsync!(void)("nvim_set_current_line", line);

    }

    void delCurrentLine() {

        client.call!(void)("nvim_del_current_line");

    }

    void delCurrentLineAsync() {

        client.callAsync!(void)("nvim_del_current_line");

    }

    void delVar(string name) {

        client.call!(void)("nvim_del_var", name);

    }

    void delVarAsync(string name) {

        client.callAsync!(void)("nvim_del_var", name);

    }

    void outWrite(string str) {

        client.call!(void)("nvim_out_write", str);

    }

    void outWriteAsync(string str) {

        client.callAsync!(void)("nvim_out_write", str);

    }

    void errWrite(string str) {

        client.call!(void)("nvim_err_write", str);

    }

    void errWriteAsync(string str) {

        client.callAsync!(void)("nvim_err_write", str);

    }

    void errWriteln(string str) {

        client.call!(void)("nvim_err_writeln", str);

    }

    void errWritelnAsync(string str) {

        client.callAsync!(void)("nvim_err_writeln", str);

    }

    Buffer[] listBufs() {

        return client.call!(ExtValue[])("nvim_list_bufs");

    }

    Buffer getCurrentBuf() {

        return client.call!(ExtValue)("nvim_get_current_buf");

    }

    void setCurrentBuf(Buffer buffer) {

        client.call!(void)("nvim_set_current_buf", buffer);

    }

    void setCurrentBufAsync(Buffer buffer) {

        client.callAsync!(void)("nvim_set_current_buf", buffer);

    }

    Window[] listWins() {

        return client.call!(ExtValue[])("nvim_list_wins");

    }

    Window getCurrentWin() {

        return client.call!(ExtValue)("nvim_get_current_win");

    }

    void setCurrentWin(Window window) {

        client.call!(void)("nvim_set_current_win", window);

    }

    void setCurrentWinAsync(Window window) {

        client.callAsync!(void)("nvim_set_current_win", window);

    }

    Tabpage[] listTabpages() {

        return client.call!(ExtValue[])("nvim_list_tabpages");

    }

    Tabpage getCurrentTabpage() {

        return client.call!(ExtValue)("nvim_get_current_tabpage");

    }

    void setCurrentTabpage(Tabpage tabpage) {

        client.call!(void)("nvim_set_current_tabpage", tabpage);

    }

    void setCurrentTabpageAsync(Tabpage tabpage) {

        client.callAsync!(void)("nvim_set_current_tabpage", tabpage);

    }

    void subscribe(string event) {

        client.call!(void)("nvim_subscribe", event);

    }

    void subscribeAsync(string event) {

        client.callAsync!(void)("nvim_subscribe", event);

    }

    void unsubscribe(string event) {

        client.call!(void)("nvim_unsubscribe", event);

    }

    void unsubscribeAsync(string event) {

        client.callAsync!(void)("nvim_unsubscribe", event);

    }

    int getColorByName(string name) {

        return client.call!(int)("nvim_get_color_by_name", name);

    }

    Buffer winGetBuf(Window window) {

        return client.call!(ExtValue)("nvim_win_get_buf", window);

    }

    int[2] winGetCursor(Window window) {

        return client.call!(int[2])("nvim_win_get_cursor", window);

    }

    void winSetCursor(Window window, int[2] pos) {

        client.call!(void)("nvim_win_set_cursor", window , pos);

    }

    void winSetCursorAsync(Window window, int[2] pos) {

        client.callAsync!(void)("nvim_win_set_cursor", window , pos);

    }

    int winGetHeight(Window window) {

        return client.call!(int)("nvim_win_get_height", window);

    }

    void winSetHeight(Window window, int height) {

        client.call!(void)("nvim_win_set_height", window , height);

    }

    void winSetHeightAsync(Window window, int height) {

        client.callAsync!(void)("nvim_win_set_height", window , height);

    }

    int winGetWidth(Window window) {

        return client.call!(int)("nvim_win_get_width", window);

    }

    void winSetWidth(Window window, int width) {

        client.call!(void)("nvim_win_set_width", window , width);

    }

    void winSetWidthAsync(Window window, int width) {

        client.callAsync!(void)("nvim_win_set_width", window , width);

    }

    void winDelVar(Window window, string name) {

        client.call!(void)("nvim_win_del_var", window , name);

    }

    void winDelVarAsync(Window window, string name) {

        client.callAsync!(void)("nvim_win_del_var", window , name);

    }

    int[2] winGetPosition(Window window) {

        return client.call!(int[2])("nvim_win_get_position", window);

    }

    Tabpage winGetTabpage(Window window) {

        return client.call!(ExtValue)("nvim_win_get_tabpage", window);

    }

    int winGetNumber(Window window) {

        return client.call!(int)("nvim_win_get_number", window);

    }

    bool winIsValid(Window window) {

        return client.call!(bool)("nvim_win_is_valid", window);

    }

    int bufferLineCount(Buffer buffer) {

        return client.call!(int)("buffer_line_count", buffer);

    }

    string[] bufferGetLines(Buffer buffer, int start, int end, bool strict_indexing) {

        return client.call!(string[])("buffer_get_lines", buffer , start , end , strict_indexing);

    }

    void bufferSetLines(Buffer buffer, int start, int end, bool strict_indexing, string[] replacement) {

        client.call!(void)("buffer_set_lines", buffer , start , end , strict_indexing , replacement);

    }

    void bufferSetLinesAsync(Buffer buffer, int start, int end, bool strict_indexing, string[] replacement) {

        client.callAsync!(void)("buffer_set_lines", buffer , start , end , strict_indexing , replacement);

    }

    int bufferGetNumber(Buffer buffer) {

        return client.call!(int)("buffer_get_number", buffer);

    }

    string bufferGetName(Buffer buffer) {

        return client.call!(string)("buffer_get_name", buffer);

    }

    void bufferSetName(Buffer buffer, string name) {

        client.call!(void)("buffer_set_name", buffer , name);

    }

    void bufferSetNameAsync(Buffer buffer, string name) {

        client.callAsync!(void)("buffer_set_name", buffer , name);

    }

    bool bufferIsValid(Buffer buffer) {

        return client.call!(bool)("buffer_is_valid", buffer);

    }

    int[2] bufferGetMark(Buffer buffer, string name) {

        return client.call!(int[2])("buffer_get_mark", buffer , name);

    }

    int bufferAddHighlight(Buffer buffer, int src_id, string hl_group, int line, int col_start, int col_end) {

        return client.call!(int)("buffer_add_highlight", buffer , src_id , hl_group , line , col_start , col_end);

    }

    void bufferClearHighlight(Buffer buffer, int src_id, int line_start, int line_end) {

        client.call!(void)("buffer_clear_highlight", buffer , src_id , line_start , line_end);

    }

    void bufferClearHighlightAsync(Buffer buffer, int src_id, int line_start, int line_end) {

        client.callAsync!(void)("buffer_clear_highlight", buffer , src_id , line_start , line_end);

    }

    Window[] tabpageGetWindows(Tabpage tabpage) {

        return client.call!(ExtValue[])("tabpage_get_windows", tabpage);

    }

    Window tabpageGetWindow(Tabpage tabpage) {

        return client.call!(ExtValue)("tabpage_get_window", tabpage);

    }

    bool tabpageIsValid(Tabpage tabpage) {

        return client.call!(bool)("tabpage_is_valid", tabpage);

    }

    void uiDetach() {

        client.call!(void)("ui_detach");

    }

    void uiDetachAsync() {

        client.callAsync!(void)("ui_detach");

    }

    void vimCommand(string command) {

        client.call!(void)("vim_command", command);

    }

    void vimCommandAsync(string command) {

        client.callAsync!(void)("vim_command", command);

    }

    void vimFeedkeys(string keys, string mode, bool escape_csi) {

        client.call!(void)("vim_feedkeys", keys , mode , escape_csi);

    }

    void vimFeedkeysAsync(string keys, string mode, bool escape_csi) {

        client.callAsync!(void)("vim_feedkeys", keys , mode , escape_csi);

    }

    int vimInput(string keys) {

        return client.call!(int)("vim_input", keys);

    }

    string vimReplaceTermcodes(string str, bool from_part, bool do_lt, bool special) {

        return client.call!(string)("vim_replace_termcodes", str , from_part , do_lt , special);

    }

    string vimCommandOutput(string command) {

        return client.call!(string)("vim_command_output", command);

    }

    int vimStrwidth(string text) {

        return client.call!(int)("vim_strwidth", text);

    }

    string[] vimListRuntimePaths() {

        return client.call!(string[])("vim_list_runtime_paths");

    }

    void vimChangeDirectory(string dir) {

        client.call!(void)("vim_change_directory", dir);

    }

    void vimChangeDirectoryAsync(string dir) {

        client.callAsync!(void)("vim_change_directory", dir);

    }

    string vimGetCurrentLine() {

        return client.call!(string)("vim_get_current_line");

    }

    void vimSetCurrentLine(string line) {

        client.call!(void)("vim_set_current_line", line);

    }

    void vimSetCurrentLineAsync(string line) {

        client.callAsync!(void)("vim_set_current_line", line);

    }

    void vimDelCurrentLine() {

        client.call!(void)("vim_del_current_line");

    }

    void vimDelCurrentLineAsync() {

        client.callAsync!(void)("vim_del_current_line");

    }

    void vimOutWrite(string str) {

        client.call!(void)("vim_out_write", str);

    }

    void vimOutWriteAsync(string str) {

        client.callAsync!(void)("vim_out_write", str);

    }

    void vimErrWrite(string str) {

        client.call!(void)("vim_err_write", str);

    }

    void vimErrWriteAsync(string str) {

        client.callAsync!(void)("vim_err_write", str);

    }

    void vimReportError(string str) {

        client.call!(void)("vim_report_error", str);

    }

    void vimReportErrorAsync(string str) {

        client.callAsync!(void)("vim_report_error", str);

    }

    Buffer[] vimGetBuffers() {

        return client.call!(ExtValue[])("vim_get_buffers");

    }

    Buffer vimGetCurrentBuffer() {

        return client.call!(ExtValue)("vim_get_current_buffer");

    }

    void vimSetCurrentBuffer(Buffer buffer) {

        client.call!(void)("vim_set_current_buffer", buffer);

    }

    void vimSetCurrentBufferAsync(Buffer buffer) {

        client.callAsync!(void)("vim_set_current_buffer", buffer);

    }

    Window[] vimGetWindows() {

        return client.call!(ExtValue[])("vim_get_windows");

    }

    Window vimGetCurrentWindow() {

        return client.call!(ExtValue)("vim_get_current_window");

    }

    void vimSetCurrentWindow(Window window) {

        client.call!(void)("vim_set_current_window", window);

    }

    void vimSetCurrentWindowAsync(Window window) {

        client.callAsync!(void)("vim_set_current_window", window);

    }

    Tabpage[] vimGetTabpages() {

        return client.call!(ExtValue[])("vim_get_tabpages");

    }

    Tabpage vimGetCurrentTabpage() {

        return client.call!(ExtValue)("vim_get_current_tabpage");

    }

    void vimSetCurrentTabpage(Tabpage tabpage) {

        client.call!(void)("vim_set_current_tabpage", tabpage);

    }

    void vimSetCurrentTabpageAsync(Tabpage tabpage) {

        client.callAsync!(void)("vim_set_current_tabpage", tabpage);

    }

    void vimSubscribe(string event) {

        client.call!(void)("vim_subscribe", event);

    }

    void vimSubscribeAsync(string event) {

        client.callAsync!(void)("vim_subscribe", event);

    }

    void vimUnsubscribe(string event) {

        client.call!(void)("vim_unsubscribe", event);

    }

    void vimUnsubscribeAsync(string event) {

        client.callAsync!(void)("vim_unsubscribe", event);

    }

    int vimNameToColor(string name) {

        return client.call!(int)("vim_name_to_color", name);

    }

    Buffer windowGetBuffer(Window window) {

        return client.call!(ExtValue)("window_get_buffer", window);

    }

    int[2] windowGetCursor(Window window) {

        return client.call!(int[2])("window_get_cursor", window);

    }

    void windowSetCursor(Window window, int[2] pos) {

        client.call!(void)("window_set_cursor", window , pos);

    }

    void windowSetCursorAsync(Window window, int[2] pos) {

        client.callAsync!(void)("window_set_cursor", window , pos);

    }

    int windowGetHeight(Window window) {

        return client.call!(int)("window_get_height", window);

    }

    void windowSetHeight(Window window, int height) {

        client.call!(void)("window_set_height", window , height);

    }

    void windowSetHeightAsync(Window window, int height) {

        client.callAsync!(void)("window_set_height", window , height);

    }

    int windowGetWidth(Window window) {

        return client.call!(int)("window_get_width", window);

    }

    void windowSetWidth(Window window, int width) {

        client.call!(void)("window_set_width", window , width);

    }

    void windowSetWidthAsync(Window window, int width) {

        client.callAsync!(void)("window_set_width", window , width);

    }

    int[2] windowGetPosition(Window window) {

        return client.call!(int[2])("window_get_position", window);

    }

    Tabpage windowGetTabpage(Window window) {

        return client.call!(ExtValue)("window_get_tabpage", window);

    }

    bool windowIsValid(Window window) {

        return client.call!(bool)("window_is_valid", window);

    }

}

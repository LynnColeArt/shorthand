pub const RequestContext = struct {
    method: []const u8 = "GET",
    script_name: []const u8 = "",
    path_info: []const u8 = "",
    query_string: []const u8 = "",
    body: []const u8 = "",
    cookie_header: []const u8 = "",
    remote_addr: []const u8 = "",
    user_agent: []const u8 = "",
    legacy_mode: bool = true,
};

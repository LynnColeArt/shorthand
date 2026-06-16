const response = @import("response.zig");
const runtime = @import("runtime.zig");

pub const Category = enum {
    request_response,
    text,
    date_time,
    numeric,
    file,
    database,
    object,
};

pub fn categoryName(category: Category) []const u8 {
    return switch (category) {
        .request_response => "request_response",
        .text => "text",
        .date_time => "date_time",
        .numeric => "numeric",
        .file => "file",
        .database => "database",
        .object => "object",
    };
}

pub fn notImplemented(name: []const u8) error{NotImplemented}!void {
    _ = name;
    return error.NotImplemented;
}

pub fn header(rt: *runtime.Runtime, name: []const u8, value: []const u8) response.Error!void {
    try rt.setHeader(name, value);
}

pub fn SetCookie(rt: *runtime.Runtime, cookie: response.CookieSpec) response.Error!void {
    try rt.setCookie(cookie);
}

pub fn redirect(rt: *runtime.Runtime, location: []const u8) response.Error!void {
    try rt.redirect(location);
}

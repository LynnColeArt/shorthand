const std = @import("std");

pub const Error = error{
    HeadersAlreadySent,
    InvalidHeaderName,
    InvalidHeaderValue,
    InvalidStatusCode,
    InvalidCookieName,
    OutOfMemory,
};

pub const Header = struct {
    name: []const u8,
    value: []const u8,
};

pub const CookieSpec = struct {
    name: []const u8,
    value: []const u8 = "",
    path: ?[]const u8 = null,
    domain: ?[]const u8 = null,
    expires: ?[]const u8 = null,
    secure: bool = false,
};

pub const ResponseState = struct {
    status_code: u16 = 200,
    content_type: []const u8 = "text/html",
    content_type_owned: bool = false,
    headers_committed: bool = false,
    headers_written: bool = false,
    body_started: bool = false,
    bytes_written: usize = 0,
    headers: std.ArrayList(Header) = .empty,
    cookies: std.ArrayList(CookieSpec) = .empty,

    pub fn deinit(self: *ResponseState, allocator: std.mem.Allocator) void {
        if (self.content_type_owned) {
            allocator.free(self.content_type);
        }
        self.content_type = "text/html";
        self.content_type_owned = false;

        for (self.headers.items) |header| {
            allocator.free(header.name);
            allocator.free(header.value);
        }
        self.headers.deinit(allocator);

        for (self.cookies.items) |cookie| {
            allocator.free(cookie.name);
            allocator.free(cookie.value);
            if (cookie.path) |path| allocator.free(path);
            if (cookie.domain) |domain| allocator.free(domain);
            if (cookie.expires) |expires| allocator.free(expires);
        }
        self.cookies.deinit(allocator);
        self.headers = .empty;
        self.cookies = .empty;
    }

    pub fn canMutateHeaders(self: *const ResponseState) bool {
        return !self.headers_committed and !self.body_started;
    }

    pub fn commitHeaders(self: *ResponseState) void {
        self.headers_committed = true;
    }

    pub fn beginBody(self: *ResponseState) void {
        self.body_started = true;
        self.headers_committed = true;
    }

    pub fn noteWrite(self: *ResponseState, count: usize) void {
        if (count == 0) return;
        self.beginBody();
        self.bytes_written += count;
    }

    fn ensureMutable(self: *const ResponseState) Error!void {
        if (!self.canMutateHeaders()) return error.HeadersAlreadySent;
    }

    fn validateHeaderName(name: []const u8) bool {
        return name.len != 0 and std.mem.indexOfAny(u8, name, ":\r\n") == null;
    }

    fn validateHeaderValue(value: []const u8) bool {
        return std.mem.indexOfAny(u8, value, "\r\n") == null;
    }

    fn validateCookieName(name: []const u8) bool {
        if (name.len == 0) return false;
        for (name) |c| {
            if (std.ascii.isWhitespace(c)) return false;
            switch (c) {
                '=', ';', ',', '\r', '\n' => return false,
                else => {},
            }
        }
        return true;
    }

    fn parseStatusCode(value: []const u8) Error!u16 {
        var end: usize = 0;
        while (end < value.len and std.ascii.isDigit(value[end])) : (end += 1) {}
        if (end == 0) return error.InvalidStatusCode;
        return std.fmt.parseInt(u16, value[0..end], 10) catch error.InvalidStatusCode;
    }

    fn statusReasonPhrase(code: u16) []const u8 {
        return switch (code) {
            200 => "OK",
            201 => "Created",
            204 => "No Content",
            301 => "Moved Permanently",
            302 => "Found",
            303 => "See Other",
            307 => "Temporary Redirect",
            308 => "Permanent Redirect",
            400 => "Bad Request",
            401 => "Unauthorized",
            403 => "Forbidden",
            404 => "Not Found",
            500 => "Internal Server Error",
            502 => "Bad Gateway",
            else => "",
        };
    }

    fn writeCookie(writer: anytype, cookie: CookieSpec) anyerror!void {
        if (!validateCookieName(cookie.name)) return error.InvalidCookieName;
        if (!validateHeaderValue(cookie.value)) return error.InvalidHeaderValue;

        try writer.print("{s}={s}", .{ cookie.name, cookie.value });

        if (cookie.expires) |expires| {
            if (!validateHeaderValue(expires)) return error.InvalidHeaderValue;
            try writer.print("; Expires={s}", .{expires});
        }
        if (cookie.path) |path| {
            if (!validateHeaderValue(path)) return error.InvalidHeaderValue;
            try writer.print("; Path={s}", .{path});
        }
        if (cookie.domain) |domain| {
            if (!validateHeaderValue(domain)) return error.InvalidHeaderValue;
            try writer.print("; Domain={s}", .{domain});
        }
        if (cookie.secure) {
            try writer.writeAll("; Secure");
        }
    }

    pub fn setHeader(self: *ResponseState, allocator: std.mem.Allocator, name: []const u8, value: []const u8) Error!void {
        if (!validateHeaderName(name)) return error.InvalidHeaderName;
        if (!validateHeaderValue(value)) return error.InvalidHeaderValue;
        try self.ensureMutable();

        if (std.ascii.eqlIgnoreCase(name, "Content-Type")) {
            const owned_value = try allocator.dupe(u8, value);
            if (self.content_type_owned) allocator.free(self.content_type);
            self.content_type = owned_value;
            self.content_type_owned = true;
            return;
        }
        if (std.ascii.eqlIgnoreCase(name, "Status")) {
            self.status_code = try parseStatusCode(value);
            return;
        }

        const owned_name = try allocator.dupe(u8, name);
        errdefer allocator.free(owned_name);
        const owned_value = try allocator.dupe(u8, value);
        errdefer allocator.free(owned_value);
        try self.headers.append(allocator, .{
            .name = owned_name,
            .value = owned_value,
        });
    }

    pub fn setCookie(self: *ResponseState, allocator: std.mem.Allocator, cookie: CookieSpec) Error!void {
        if (!validateCookieName(cookie.name)) return error.InvalidCookieName;
        if (!validateHeaderValue(cookie.value)) return error.InvalidHeaderValue;
        if (cookie.path) |path| {
            if (!validateHeaderValue(path)) return error.InvalidHeaderValue;
        }
        if (cookie.domain) |domain| {
            if (!validateHeaderValue(domain)) return error.InvalidHeaderValue;
        }
        if (cookie.expires) |expires| {
            if (!validateHeaderValue(expires)) return error.InvalidHeaderValue;
        }

        try self.ensureMutable();
        const owned_name = try allocator.dupe(u8, cookie.name);
        errdefer allocator.free(owned_name);
        const owned_value = try allocator.dupe(u8, cookie.value);
        errdefer allocator.free(owned_value);
        const owned_path = if (cookie.path) |path| try allocator.dupe(u8, path) else null;
        errdefer if (owned_path) |path| allocator.free(path);
        const owned_domain = if (cookie.domain) |domain| try allocator.dupe(u8, domain) else null;
        errdefer if (owned_domain) |domain| allocator.free(domain);
        const owned_expires = if (cookie.expires) |expires| try allocator.dupe(u8, expires) else null;
        errdefer if (owned_expires) |expires| allocator.free(expires);
        try self.cookies.append(allocator, .{
            .name = owned_name,
            .value = owned_value,
            .path = owned_path,
            .domain = owned_domain,
            .expires = owned_expires,
            .secure = cookie.secure,
        });
    }

    pub fn redirect(self: *ResponseState, allocator: std.mem.Allocator, location: []const u8) Error!void {
        if (!validateHeaderValue(location)) return error.InvalidHeaderValue;
        try self.ensureMutable();
        self.status_code = 302;
        const owned_name = try allocator.dupe(u8, "Location");
        errdefer allocator.free(owned_name);
        const owned_location = try allocator.dupe(u8, location);
        errdefer allocator.free(owned_location);
        try self.headers.append(allocator, .{
            .name = owned_name,
            .value = owned_location,
        });
    }

    pub fn writeHeaders(self: *ResponseState, writer: anytype) anyerror!void {
        if (self.headers_written) return error.HeadersAlreadySent;
        self.headers_written = true;
        self.commitHeaders();

        if (self.status_code != 200) {
            const reason = statusReasonPhrase(self.status_code);
            if (reason.len != 0) {
                try writer.print("Status: {d} {s}\r\n", .{ self.status_code, reason });
            } else {
                try writer.print("Status: {d}\r\n", .{self.status_code});
            }
        }

        if (self.content_type.len != 0) {
            try writer.print("Content-Type: {s}\r\n", .{self.content_type});
        }

        for (self.headers.items) |header| {
            try writer.print("{s}: {s}\r\n", .{ header.name, header.value });
        }

        for (self.cookies.items) |cookie| {
            try writer.writeAll("Set-Cookie: ");
            try writeCookie(writer, cookie);
            try writer.writeAll("\r\n");
        }

        try writer.writeAll("\r\n");
    }
};

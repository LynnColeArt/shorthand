const std = @import("std");

pub const BackendKind = enum {
    legacy,
    sqlite,
    shovelerdb,
    postgres,
    mysql,
    odbc,
    mongo,
    unknown,
};

pub const ConnectionPolicy = struct {
    auto_refresh: bool = true,
    reconnect: bool = true,
    idle_timeout_seconds: ?u64 = 30 * std.time.s_per_min,
    max_age_seconds: ?u64 = 8 * std.time.s_per_hour,
};

pub const ConnectionSpec = struct {
    backend: BackendKind = .unknown,
    driver_name: []u8 = &[_]u8{},
    connection_string: []u8 = &[_]u8{},
    policy: ConnectionPolicy = .{},

    pub fn deinit(self: *ConnectionSpec, allocator: std.mem.Allocator) void {
        allocator.free(self.driver_name);
        allocator.free(self.connection_string);
        self.* = .{};
    }
};

pub const ConnectionStatus = struct {
    backend: BackendKind,
    driver_name: []const u8,
    connection_string: []const u8,
    opened_at: i64,
    last_used_at: i64,
    last_refresh_at: i64,
    generation: u64,
    refresh_count: u64,
    policy: ConnectionPolicy,
    stale: bool,
};

pub fn backendName(kind: BackendKind) []const u8 {
    return switch (kind) {
        .legacy => "legacy",
        .sqlite => "sqlite",
        .shovelerdb => "shovelerdb",
        .postgres => "postgres",
        .mysql => "mysql",
        .odbc => "odbc",
        .mongo => "mongo",
        .unknown => "unknown",
    };
}

pub fn currentUnixSeconds() i64 {
    var ts: std.posix.timespec = undefined;
    switch (std.posix.errno(std.posix.system.clock_gettime(.REALTIME, &ts))) {
        .SUCCESS => return @as(i64, @intCast(ts.sec)),
        else => return 0,
    }
}

fn eqlIgnoreCase(a: []const u8, b: []const u8) bool {
    return std.ascii.eqlIgnoreCase(a, b);
}

fn detectBackendName(name: []const u8) BackendKind {
    if (name.len == 0) return .unknown;
    if (eqlIgnoreCase(name, "mysql") or eqlIgnoreCase(name, "mariadb")) return .mysql;
    if (eqlIgnoreCase(name, "postgres") or eqlIgnoreCase(name, "postgresql") or eqlIgnoreCase(name, "pgsql")) return .postgres;
    if (eqlIgnoreCase(name, "sqlite") or eqlIgnoreCase(name, "sqlite3")) return .sqlite;
    if (eqlIgnoreCase(name, "odbc") or eqlIgnoreCase(name, "unixodbc")) return .odbc;
    if (eqlIgnoreCase(name, "mongo") or eqlIgnoreCase(name, "mongodb")) return .mongo;
    if (eqlIgnoreCase(name, "shoveler") or eqlIgnoreCase(name, "shovelerdb")) return .shovelerdb;
    if (eqlIgnoreCase(name, "legacy") or eqlIgnoreCase(name, "shorthand")) return .legacy;
    return .unknown;
}

fn parseBool(text: []const u8) ?bool {
    if (text.len == 0) return null;
    if (eqlIgnoreCase(text, "1") or eqlIgnoreCase(text, "true") or eqlIgnoreCase(text, "yes") or eqlIgnoreCase(text, "on") or eqlIgnoreCase(text, "always")) {
        return true;
    }
    if (eqlIgnoreCase(text, "0") or eqlIgnoreCase(text, "false") or eqlIgnoreCase(text, "no") or eqlIgnoreCase(text, "off") or eqlIgnoreCase(text, "never")) {
        return false;
    }
    return null;
}

fn parseDurationSeconds(text: []const u8) ?u64 {
    const trimmed = std.mem.trim(u8, text, " \t\r\n");
    if (trimmed.len == 0) return null;

    const suffix = trimmed[trimmed.len - 1];
    const digits = switch (suffix) {
        's', 'S', 'm', 'M', 'h', 'H', 'd', 'D' => trimmed[0 .. trimmed.len - 1],
        else => trimmed,
    };

    const amount = std.fmt.parseInt(u64, digits, 10) catch return null;
    const multiplier: u64 = switch (suffix) {
        'm', 'M' => std.time.s_per_min,
        'h', 'H' => std.time.s_per_hour,
        'd', 'D' => std.time.s_per_day,
        else => 1,
    };

    const ov = @mulWithOverflow(amount, multiplier);
    if (ov[1] != 0) return null;
    return ov[0];
}

fn parsePolicyOverride(spec: *ConnectionSpec, key: []const u8, value: []const u8) void {
    if (eqlIgnoreCase(key, "backend") or eqlIgnoreCase(key, "driver")) {
        const backend = detectBackendName(value);
        if (backend != .unknown) spec.backend = backend;
        return;
    }

    if (eqlIgnoreCase(key, "refresh") or eqlIgnoreCase(key, "auto_refresh")) {
        if (parseBool(value)) |enabled| spec.policy.auto_refresh = enabled;
        return;
    }

    if (eqlIgnoreCase(key, "reconnect")) {
        if (parseBool(value)) |enabled| spec.policy.reconnect = enabled;
        return;
    }

    if (eqlIgnoreCase(key, "idle_timeout") or eqlIgnoreCase(key, "idle_timeout_seconds")) {
        if (parseDurationSeconds(value)) |seconds| spec.policy.idle_timeout_seconds = seconds;
        return;
    }

    if (eqlIgnoreCase(key, "max_age") or eqlIgnoreCase(key, "max_age_seconds")) {
        if (parseDurationSeconds(value)) |seconds| spec.policy.max_age_seconds = seconds;
        return;
    }
}

fn parseConnectionOptions(spec: *ConnectionSpec) void {
    var segments = std.mem.splitAny(u8, spec.connection_string, "?;&");
    while (segments.next()) |segment| {
        const trimmed = std.mem.trim(u8, segment, " \t\r\n");
        if (trimmed.len == 0) continue;
        const eq = std.mem.indexOfScalar(u8, trimmed, '=') orelse continue;
        const key = std.mem.trim(u8, trimmed[0..eq], " \t\r\n");
        const value = std.mem.trim(u8, trimmed[eq + 1 ..], " \t\r\n");
        if (key.len == 0) continue;
        parsePolicyOverride(spec, key, value);
    }
}

pub fn createConnectionSpec(allocator: std.mem.Allocator, driver_name: []const u8, connection_string: []const u8) !ConnectionSpec {
    var spec: ConnectionSpec = .{
        .backend = detectBackendName(driver_name),
        .driver_name = try allocator.dupe(u8, driver_name),
        .connection_string = try allocator.dupe(u8, connection_string),
        .policy = .{},
    };
    parseConnectionOptions(&spec);
    return spec;
}

fn secondsSince(now: i64, earlier: i64) u64 {
    if (now <= earlier) return 0;
    return @as(u64, @intCast(now - earlier));
}

pub fn isConnectionStale(status: ConnectionStatus) bool {
    const now = currentUnixSeconds();
    if (status.opened_at == 0 or status.last_used_at == 0) return false;

    if (status.policy.idle_timeout_seconds) |idle_timeout| {
        if (secondsSince(now, status.last_used_at) >= idle_timeout) return true;
    }

    if (status.policy.max_age_seconds) |max_age| {
        if (secondsSince(now, status.opened_at) >= max_age) return true;
    }

    return false;
}

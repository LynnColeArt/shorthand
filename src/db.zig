const std = @import("std");
const sqlite = @cImport({
    @cInclude("sqlite3.h");
});
const value = @import("value.zig");

const legacy_dump = @embedFile("data/smoses_secondary.sql");

pub const ConnectionState = struct {
    db: ?*sqlite.sqlite3 = null,
};

const Field = struct {
    name: []u8,
    value: value.Value,
};

const Row = struct {
    fields: []Field,
};

pub const RecordsetState = struct {
    connection: *ConnectionState,
    sql: []u8,
    rows: std.ArrayList(Row) = .empty,
    position: isize = -1,
};

pub const DdlState = struct {
    connection: *ConnectionState,
    sql: []u8,
};

fn hasPrefixIgnoreCase(text: []const u8, prefix: []const u8) bool {
    return text.len >= prefix.len and std.ascii.eqlIgnoreCase(text[0..prefix.len], prefix);
}

fn sqliteError(db: ?*sqlite.sqlite3) anyerror {
    _ = db;
    return error.SqliteError;
}

fn execSql(allocator: std.mem.Allocator, db: *sqlite.sqlite3, sql: []const u8) anyerror!void {
    const c_sql = try allocator.dupeZ(u8, sql);
    defer allocator.free(c_sql);

    var errmsg: [*c]u8 = null;
    const rc = sqlite.sqlite3_exec(db, c_sql.ptr, null, null, &errmsg);
    if (rc != sqlite.SQLITE_OK) {
        if (@intFromPtr(errmsg) != 0) sqlite.sqlite3_free(errmsg);
        return sqliteError(db);
    }
}

fn normalizeMySqlEscapes(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const output = try allocator.alloc(u8, input.len);
    var out_index: usize = 0;
    var i: usize = 0;
    while (i < input.len) {
        if (input[i] == '\\' and i + 1 < input.len and input[i + 1] == '\'') {
            output[out_index] = '\'';
            output[out_index + 1] = '\'';
            out_index += 2;
            i += 2;
            continue;
        }
        output[out_index] = input[i];
        out_index += 1;
        i += 1;
    }
    return output;
}

fn createSchema(allocator: std.mem.Allocator, db: *sqlite.sqlite3) anyerror!void {
    const schema_statements = [_][]const u8{
        \\CREATE TABLE IF NOT EXISTS cart_categories (
        \\  CategoryID INTEGER PRIMARY KEY,
        \\  CategoryName TEXT
        \\);
        ,
        \\CREATE TABLE IF NOT EXISTS cart_configuration (
        \\  autoid INTEGER PRIMARY KEY,
        \\  primary_color TEXT DEFAULT '#fffff',
        \\  secondary_color TEXT DEFAULT '#e1e1e',
        \\  code_thumbnail TEXT DEFAULT '',
        \\  thumbnails INTEGER DEFAULT 0,
        \\  allow_subs INTEGER DEFAULT 0,
        \\  reviews INTEGER DEFAULT 0,
        \\  alsobought INTEGER DEFAULT 0,
        \\  currency TEXT DEFAULT '0',
        \\  title TEXT DEFAULT '0',
        \\  desc_length INTEGER DEFAULT 0
        \\);
        ,
        \\CREATE TABLE IF NOT EXISTS cart_customers (
        \\  CustomerID INTEGER PRIMARY KEY,
        \\  FullName TEXT,
        \\  EmailAddress TEXT,
        \\  Password TEXT
        \\);
        ,
        \\CREATE TABLE IF NOT EXISTS cart_orderdetails (
        \\  autoid INTEGER PRIMARY KEY AUTOINCREMENT,
        \\  orderstate INTEGER NOT NULL DEFAULT 0,
        \\  OrderID TEXT NOT NULL DEFAULT '0',
        \\  ProductID INTEGER NOT NULL DEFAULT 0,
        \\  Quantity INTEGER DEFAULT 0
        \\);
        ,
        \\CREATE TABLE IF NOT EXISTS cart_orders (
        \\  OrderID TEXT PRIMARY KEY,
        \\  CustomerID INTEGER DEFAULT 0,
        \\  OrderDate INTEGER NOT NULL,
        \\  ShipDate TEXT DEFAULT '0000-00-00 00:00:00'
        \\);
        ,
        \\CREATE TABLE IF NOT EXISTS cart_products (
        \\  ProductID INTEGER PRIMARY KEY,
        \\  CategoryID INTEGER DEFAULT 0,
        \\  ModelNumber TEXT,
        \\  ModelName TEXT,
        \\  ProductImage TEXT,
        \\  ProductStatus INTEGER NOT NULL DEFAULT 1,
        \\  Productstock INTEGER NOT NULL DEFAULT 0,
        \\  UnitCost REAL DEFAULT 0.0,
        \\  Description TEXT
        \\);
    };

    for (schema_statements) |stmt| {
        try execSql(allocator, db, stmt);
    }
}

fn importDump(allocator: std.mem.Allocator, db: *sqlite.sqlite3) anyerror!void {
    var lines = std.mem.splitScalar(u8, legacy_dump, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0) continue;
        if (!hasPrefixIgnoreCase(trimmed, "INSERT INTO")) continue;

        const normalized = try normalizeMySqlEscapes(allocator, trimmed);
        defer allocator.free(normalized);
        try execSql(allocator, db, normalized);
    }
}

fn loadLegacyDatabase(allocator: std.mem.Allocator, db: *sqlite.sqlite3) anyerror!void {
    try createSchema(allocator, db);
    try importDump(allocator, db);
}

pub fn createConnection(allocator: std.mem.Allocator, driver: []const u8, connection_string: []const u8) anyerror!value.ObjectValue {
    _ = driver;
    _ = connection_string;

    const state = try allocator.create(ConnectionState);
    errdefer allocator.destroy(state);
    state.* = .{};

    var raw_db: *sqlite.sqlite3 = undefined;
    const pp_db: [*c]*sqlite.sqlite3 = @ptrCast(&raw_db);
    const rc = sqlite.sqlite3_open(":memory:", pp_db);
    if (rc != sqlite.SQLITE_OK) {
        return error.SqliteError;
    }

    state.db = raw_db;
    errdefer {
        if (state.db) |db| _ = sqlite.sqlite3_close(db);
    }
    try loadLegacyDatabase(allocator, state.db.?);
    return .{ .kind = .connection, .ptr = state };
}

pub fn createRecordset(allocator: std.mem.Allocator, connection: *ConnectionState, sql: []const u8) anyerror!value.ObjectValue {
    const state = try allocator.create(RecordsetState);
    errdefer allocator.destroy(state);
    state.* = .{
        .connection = connection,
        .sql = try allocator.dupe(u8, sql),
    };
    return .{ .kind = .recordset, .ptr = state };
}

pub fn createDdl(allocator: std.mem.Allocator, connection: *ConnectionState, sql: []const u8) anyerror!value.ObjectValue {
    const state = try allocator.create(DdlState);
    errdefer allocator.destroy(state);
    state.* = .{
        .connection = connection,
        .sql = try allocator.dupe(u8, sql),
    };
    return .{ .kind = .ddl, .ptr = state };
}

pub fn connectionFromValue(v: value.Value) ?*ConnectionState {
    if (v != .object) return null;
    if (v.object.kind != .connection) return null;
    return @as(*ConnectionState, @ptrCast(@alignCast(v.object.ptr)));
}

pub fn recordsetFromValue(v: value.Value) ?*RecordsetState {
    if (v != .object) return null;
    if (v.object.kind != .recordset) return null;
    return @as(*RecordsetState, @ptrCast(@alignCast(v.object.ptr)));
}

pub fn ddlFromValue(v: value.Value) ?*DdlState {
    if (v != .object) return null;
    if (v.object.kind != .ddl) return null;
    return @as(*DdlState, @ptrCast(@alignCast(v.object.ptr)));
}

fn freeDbValue(allocator: std.mem.Allocator, v: value.Value) void {
    switch (v) {
        .string => |s| allocator.free(s),
        .cookie => |cookie| {
            allocator.free(cookie.name);
            allocator.free(cookie.value);
            if (cookie.path) |path| allocator.free(path);
            if (cookie.domain) |domain| allocator.free(domain);
            if (cookie.expires) |expires| allocator.free(expires);
        },
        else => {},
    }
}

fn rowValueFromColumn(allocator: std.mem.Allocator, stmt: *sqlite.sqlite3_stmt, index: c_int) anyerror!value.Value {
    return switch (sqlite.sqlite3_column_type(stmt, index)) {
        sqlite.SQLITE_INTEGER => .{ .integer = @as(i64, @intCast(sqlite.sqlite3_column_int64(stmt, index))) },
        sqlite.SQLITE_FLOAT => .{ .float = sqlite.sqlite3_column_double(stmt, index) },
        sqlite.SQLITE_TEXT => blk: {
            const raw = sqlite.sqlite3_column_text(stmt, index) orelse break :blk .{ .string = try allocator.dupe(u8, "") };
            const len = @as(usize, @intCast(sqlite.sqlite3_column_bytes(stmt, index)));
            break :blk .{ .string = try allocator.dupe(u8, raw[0..len]) };
        },
        sqlite.SQLITE_BLOB => blk: {
            const raw = sqlite.sqlite3_column_text(stmt, index) orelse break :blk .{ .string = try allocator.dupe(u8, "") };
            const len = @as(usize, @intCast(sqlite.sqlite3_column_bytes(stmt, index)));
            break :blk .{ .string = try allocator.dupe(u8, raw[0..len]) };
        },
        else => .{ .none = {} },
    };
}

fn bindValue(stmt: *sqlite.sqlite3_stmt, index: c_int, v: value.Value) anyerror!void {
    const rc = switch (v) {
        .none => sqlite.sqlite3_bind_null(stmt, index),
        .boolean => |b| sqlite.sqlite3_bind_int64(stmt, index, if (b) 1 else 0),
        .integer => |i| sqlite.sqlite3_bind_int64(stmt, index, i),
        .float => |f| sqlite.sqlite3_bind_double(stmt, index, f),
        .string => |s| sqlite.sqlite3_bind_text(stmt, index, s.ptr, @as(c_int, @intCast(s.len)), null),
        .cookie => |cookie| sqlite.sqlite3_bind_text(stmt, index, cookie.value.ptr, @as(c_int, @intCast(cookie.value.len)), null),
        .object => return error.InvalidObject,
    };
    if (rc != sqlite.SQLITE_OK) return error.SqliteError;
}

fn bindArguments(stmt: *sqlite.sqlite3_stmt, args: []const value.Value) anyerror!void {
    const param_count = sqlite.sqlite3_bind_parameter_count(stmt);
    var i: c_int = 1;
    while (i <= param_count) : (i += 1) {
        if (@as(usize, @intCast(i - 1)) < args.len) {
            try bindValue(stmt, i, args[@as(usize, @intCast(i - 1))]);
        } else {
            try bindValue(stmt, i, .{ .none = {} });
        }
    }
}

fn clearRows(allocator: std.mem.Allocator, rows: *std.ArrayList(Row)) void {
    for (rows.items) |row| {
        for (row.fields) |field| {
            allocator.free(field.name);
            freeDbValue(allocator, field.value);
        }
        allocator.free(row.fields);
    }
    rows.clearRetainingCapacity();
}

fn executeQuery(
    allocator: std.mem.Allocator,
    connection: *ConnectionState,
    sql: []const u8,
    args: []const value.Value,
    collect_rows: bool,
    rows: *std.ArrayList(Row),
) anyerror!void {
    const db = connection.db orelse return error.InvalidState;
    var stmt: ?*sqlite.sqlite3_stmt = null;
    const prep_rc = sqlite.sqlite3_prepare_v2(db, sql.ptr, @as(c_int, @intCast(sql.len)), &stmt, null);
    if (prep_rc != sqlite.SQLITE_OK or stmt == null) return error.SqliteError;
    defer _ = sqlite.sqlite3_finalize(stmt.?);

    try bindArguments(stmt.?, args);

    if (!collect_rows) {
        while (true) {
            const step_rc = sqlite.sqlite3_step(stmt.?);
            if (step_rc == sqlite.SQLITE_DONE) break;
            if (step_rc == sqlite.SQLITE_ROW) continue;
            return error.SqliteError;
        }
        return;
    }

    const column_count = sqlite.sqlite3_column_count(stmt.?);
    while (true) {
        const step_rc = sqlite.sqlite3_step(stmt.?);
        if (step_rc == sqlite.SQLITE_DONE) break;
        if (step_rc != sqlite.SQLITE_ROW) return error.SqliteError;

        var field_list: std.ArrayList(Field) = .empty;
        errdefer {
            for (field_list.items) |field| {
                allocator.free(field.name);
                freeDbValue(allocator, field.value);
            }
            field_list.deinit(allocator);
        }

        var col: c_int = 0;
        while (col < column_count) : (col += 1) {
            const name_raw = sqlite.sqlite3_column_name(stmt.?, col) orelse return error.SqliteError;
            try field_list.append(allocator, .{
                .name = try allocator.dupe(u8, std.mem.span(name_raw)),
                .value = try rowValueFromColumn(allocator, stmt.?, col),
            });
        }

        try rows.append(allocator, .{
            .fields = try field_list.toOwnedSlice(allocator),
        });
    }
}

pub fn recordsetExecute(self: *RecordsetState, allocator: std.mem.Allocator, args: []const value.Value) anyerror!void {
    clearRows(allocator, &self.rows);
    self.position = -1;
    try executeQuery(allocator, self.connection, self.sql, args, true, &self.rows);
}

pub fn recordsetNext(self: *RecordsetState) void {
    if (self.position < @as(isize, @intCast(self.rows.items.len))) {
        self.position += 1;
    }
}

pub fn recordsetCount(self: *const RecordsetState) i64 {
    return @as(i64, @intCast(self.rows.items.len));
}

pub fn recordsetEof(self: *const RecordsetState) bool {
    return self.rows.items.len == 0 or self.position >= @as(isize, @intCast(self.rows.items.len));
}

pub fn recordsetBof(self: *const RecordsetState) bool {
    return self.position < 0;
}

pub fn recordsetFieldValue(self: *const RecordsetState, prop: []const u8) value.Value {
    if (recordsetEof(self)) return .{ .none = {} };
    const row_index: usize = @as(usize, @intCast(self.position));
    const row = self.rows.items[row_index];
    for (row.fields) |field| {
        if (std.ascii.eqlIgnoreCase(field.name, prop)) return field.value;
    }
    return .{ .none = {} };
}

pub fn ddlExecute(self: *DdlState, allocator: std.mem.Allocator, args: []const value.Value) anyerror!void {
    var discard = std.ArrayList(Row).empty;
    defer discard.deinit(allocator);
    try executeQuery(allocator, self.connection, self.sql, args, false, &discard);
}

pub fn deinitObject(allocator: std.mem.Allocator, object: value.ObjectValue) void {
    switch (object.kind) {
        .connection => {
            const state = @as(*ConnectionState, @ptrCast(@alignCast(object.ptr)));
            if (state.db) |db| _ = sqlite.sqlite3_close(db);
            allocator.destroy(state);
        },
        .recordset => {
            const state = @as(*RecordsetState, @ptrCast(@alignCast(object.ptr)));
            clearRows(allocator, &state.rows);
            allocator.free(state.sql);
            allocator.destroy(state);
        },
        .ddl => {
            const state = @as(*DdlState, @ptrCast(@alignCast(object.ptr)));
            allocator.free(state.sql);
            allocator.destroy(state);
        },
        .file => {},
    }
}

const std = @import("std");
const dbspec = @import("dbspec.zig");
const legacy = @import("db2.zig");
const sqlite_backend = @import("db.zig");
const value = @import("value.zig");

pub const ConnectionStatus = dbspec.ConnectionStatus;

pub const ConnectionState = struct {
    backend: dbspec.BackendKind,
    legacy: ?*legacy.ConnectionState = null,
    sqlite: ?*sqlite_backend.ConnectionState = null,
};

pub const RecordsetState = struct {
    backend: dbspec.BackendKind,
    legacy: ?*legacy.RecordsetState = null,
    sqlite: ?*sqlite_backend.RecordsetState = null,
};

pub const DdlState = struct {
    backend: dbspec.BackendKind,
    legacy: ?*legacy.DdlState = null,
    sqlite: ?*sqlite_backend.DdlState = null,
};

fn selectedBackend(kind: dbspec.BackendKind) dbspec.BackendKind {
    return switch (kind) {
        .sqlite => .sqlite,
        else => .legacy,
    };
}

fn backendName(kind: dbspec.BackendKind) []const u8 {
    return dbspec.backendName(kind);
}

fn wrapConnection(
    allocator: std.mem.Allocator,
    backend: dbspec.BackendKind,
    backend_object: value.ObjectValue,
) anyerror!value.ObjectValue {
    const state = try allocator.create(ConnectionState);
    errdefer allocator.destroy(state);

    switch (backend) {
        .sqlite => {
            const inner = sqlite_backend.connectionFromValue(.{ .object = backend_object }) orelse return error.InvalidState;
            state.* = .{ .backend = backend, .sqlite = inner };
        },
        else => {
            const inner = legacy.connectionFromValue(.{ .object = backend_object }) orelse return error.InvalidState;
            state.* = .{ .backend = backend, .legacy = inner };
        },
    }

    return .{ .kind = .connection, .ptr = state };
}

fn wrapRecordset(
    allocator: std.mem.Allocator,
    backend: dbspec.BackendKind,
    backend_object: value.ObjectValue,
) anyerror!value.ObjectValue {
    const state = try allocator.create(RecordsetState);
    errdefer allocator.destroy(state);

    switch (backend) {
        .sqlite => {
            const inner = sqlite_backend.recordsetFromValue(.{ .object = backend_object }) orelse return error.InvalidState;
            state.* = .{ .backend = backend, .sqlite = inner };
        },
        else => {
            const inner = legacy.recordsetFromValue(.{ .object = backend_object }) orelse return error.InvalidState;
            state.* = .{ .backend = backend, .legacy = inner };
        },
    }

    return .{ .kind = .recordset, .ptr = state };
}

fn wrapDdl(
    allocator: std.mem.Allocator,
    backend: dbspec.BackendKind,
    backend_object: value.ObjectValue,
) anyerror!value.ObjectValue {
    const state = try allocator.create(DdlState);
    errdefer allocator.destroy(state);

    switch (backend) {
        .sqlite => {
            const inner = sqlite_backend.ddlFromValue(.{ .object = backend_object }) orelse return error.InvalidState;
            state.* = .{ .backend = backend, .sqlite = inner };
        },
        else => {
            const inner = legacy.ddlFromValue(.{ .object = backend_object }) orelse return error.InvalidState;
            state.* = .{ .backend = backend, .legacy = inner };
        },
    }

    return .{ .kind = .ddl, .ptr = state };
}

pub fn createConnection(allocator: std.mem.Allocator, driver: []const u8, connection_string: []const u8) anyerror!value.ObjectValue {
    var spec = try dbspec.createConnectionSpec(allocator, driver, connection_string);
    defer spec.deinit(allocator);
    const routed_backend = selectedBackend(spec.backend);
    const backend_object = switch (routed_backend) {
        .sqlite => try sqlite_backend.createConnection(allocator, driver, connection_string),
        else => try legacy.createConnection(allocator, driver, connection_string),
    };
    errdefer switch (routed_backend) {
        .sqlite => sqlite_backend.deinitObject(allocator, backend_object),
        else => legacy.deinitObject(allocator, backend_object),
    };
    return try wrapConnection(allocator, spec.backend, backend_object);
}

pub fn createRecordset(allocator: std.mem.Allocator, connection: *ConnectionState, sql: []const u8) anyerror!value.ObjectValue {
    const backend_object = switch (connection.backend) {
        .sqlite => try sqlite_backend.createRecordset(allocator, connection.sqlite orelse return error.InvalidState, sql),
        else => try legacy.createRecordset(allocator, connection.legacy orelse return error.InvalidState, sql),
    };
    errdefer switch (connection.backend) {
        .sqlite => sqlite_backend.deinitObject(allocator, backend_object),
        else => legacy.deinitObject(allocator, backend_object),
    };
    return try wrapRecordset(allocator, connection.backend, backend_object);
}

pub fn createDdl(allocator: std.mem.Allocator, connection: *ConnectionState, sql: []const u8) anyerror!value.ObjectValue {
    const backend_object = switch (connection.backend) {
        .sqlite => try sqlite_backend.createDdl(allocator, connection.sqlite orelse return error.InvalidState, sql),
        else => try legacy.createDdl(allocator, connection.legacy orelse return error.InvalidState, sql),
    };
    errdefer switch (connection.backend) {
        .sqlite => sqlite_backend.deinitObject(allocator, backend_object),
        else => legacy.deinitObject(allocator, backend_object),
    };
    return try wrapDdl(allocator, connection.backend, backend_object);
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

pub fn connectionStatus(self: *const ConnectionState) ConnectionStatus {
    return switch (self.backend) {
        .sqlite => sqlite_backend.connectionStatus(self.sqlite.?),
        else => legacy.connectionStatus(self.legacy.?),
    };
}

pub fn recordsetExecute(self: *RecordsetState, allocator: std.mem.Allocator, args: []const value.Value) anyerror!void {
    switch (self.backend) {
        .sqlite => try sqlite_backend.recordsetExecute(self.sqlite.?, allocator, args),
        else => try legacy.recordsetExecute(self.legacy.?, allocator, args),
    }
}

pub fn recordsetNext(self: *RecordsetState) void {
    switch (self.backend) {
        .sqlite => sqlite_backend.recordsetNext(self.sqlite.?),
        else => legacy.recordsetNext(self.legacy.?),
    }
}

pub fn recordsetCount(self: *const RecordsetState) i64 {
    return switch (self.backend) {
        .sqlite => sqlite_backend.recordsetCount(self.sqlite.?),
        else => legacy.recordsetCount(self.legacy.?),
    };
}

pub fn recordsetEof(self: *const RecordsetState) bool {
    return switch (self.backend) {
        .sqlite => sqlite_backend.recordsetEof(self.sqlite.?),
        else => legacy.recordsetEof(self.legacy.?),
    };
}

pub fn recordsetBof(self: *const RecordsetState) bool {
    return switch (self.backend) {
        .sqlite => sqlite_backend.recordsetBof(self.sqlite.?),
        else => legacy.recordsetBof(self.legacy.?),
    };
}

pub fn recordsetFieldValue(self: *const RecordsetState, prop: []const u8) value.Value {
    return switch (self.backend) {
        .sqlite => sqlite_backend.recordsetFieldValue(self.sqlite.?, prop),
        else => legacy.recordsetFieldValue(self.legacy.?, prop),
    };
}

pub fn ddlExecute(self: *DdlState, allocator: std.mem.Allocator, args: []const value.Value) anyerror!void {
    switch (self.backend) {
        .sqlite => try sqlite_backend.ddlExecute(self.sqlite.?, allocator, args),
        else => try legacy.ddlExecute(self.legacy.?, allocator, args),
    }
}

pub fn deinitObject(allocator: std.mem.Allocator, object: value.ObjectValue) void {
    switch (object.kind) {
        .connection => {
            const state = @as(*ConnectionState, @ptrCast(@alignCast(object.ptr)));
            switch (state.backend) {
                .sqlite => sqlite_backend.deinitObject(allocator, .{ .kind = .connection, .ptr = state.sqlite.? }),
                else => legacy.deinitObject(allocator, .{ .kind = .connection, .ptr = state.legacy.? }),
            }
            allocator.destroy(state);
        },
        .recordset => {
            const state = @as(*RecordsetState, @ptrCast(@alignCast(object.ptr)));
            switch (state.backend) {
                .sqlite => sqlite_backend.deinitObject(allocator, .{ .kind = .recordset, .ptr = state.sqlite.? }),
                else => legacy.deinitObject(allocator, .{ .kind = .recordset, .ptr = state.legacy.? }),
            }
            allocator.destroy(state);
        },
        .ddl => {
            const state = @as(*DdlState, @ptrCast(@alignCast(object.ptr)));
            switch (state.backend) {
                .sqlite => sqlite_backend.deinitObject(allocator, .{ .kind = .ddl, .ptr = state.sqlite.? }),
                else => legacy.deinitObject(allocator, .{ .kind = .ddl, .ptr = state.legacy.? }),
            }
            allocator.destroy(state);
        },
        .array, .map => {},
        .file => {},
    }
}

pub fn backendLabel(self: *const ConnectionState) []const u8 {
    return backendName(self.backend);
}

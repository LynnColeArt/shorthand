const response = @import("response.zig");

pub const Value = union(enum) {
    none,
    boolean: bool,
    integer: i64,
    float: f64,
    string: []const u8,
    cookie: response.CookieSpec,
    object: ObjectValue,
};

pub const ObjectKind = enum {
    connection,
    recordset,
    ddl,
    file,
};

pub const ObjectValue = struct {
    kind: ObjectKind,
    ptr: *anyopaque,
};

pub fn isNullish(value: Value) bool {
    return switch (value) {
        .none => true,
        else => false,
    };
}

pub fn isTruthy(value: Value) bool {
    return switch (value) {
        .none => false,
        .boolean => |v| v,
        .integer => |v| v != 0,
        .float => |v| v != 0.0,
        .string => |v| v.len != 0,
        .cookie => true,
        .object => true,
    };
}

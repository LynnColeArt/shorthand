const std = @import("std");
const value = @import("value.zig");

pub const ArrayState = struct {
    allocator: std.mem.Allocator,
    allocated: bool = true,
    lower_bound: i64 = 1,
    items: std.ArrayList(value.Value) = .empty,
};

pub const MapEntry = struct {
    key: []u8,
    value: value.Value,
};

pub const MapState = struct {
    allocator: std.mem.Allocator,
    allocated: bool = true,
    entries: std.ArrayList(MapEntry) = .empty,
};

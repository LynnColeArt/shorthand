const std = @import("std");
const value = @import("value.zig");

pub const Error = error{
    OutOfMemory,
};

pub const FileState = struct {
    allocator: std.mem.Allocator,
    name: []u8,
    mode: []u8,
    last_error: ?[]u8 = null,
    handle: ?std.Io.File = null,
    readable: bool = false,
    writable: bool = false,
    append: bool = false,
    read_pos: u64 = 0,
    write_pos: u64 = 0,

    pub fn deinit(self: *FileState, allocator: std.mem.Allocator, io: std.Io) void {
        if (self.handle) |file| file.close(io);
        self.allocator.free(self.name);
        self.allocator.free(self.mode);
        if (self.last_error) |err| self.allocator.free(err);
        allocator.destroy(self);
    }

    fn clearError(self: *FileState) void {
        if (self.last_error) |err| self.allocator.free(err);
        self.last_error = null;
    }

    fn setError(self: *FileState, message: []const u8) !void {
        self.clearError();
        self.last_error = try self.allocator.dupe(u8, message);
    }

    fn setErrorFromAnyError(self: *FileState, err: anyerror) !void {
        try self.setError(errorMessage(err));
    }

    fn ensureOpenForRead(self: *FileState) !bool {
        if (self.handle == null) {
            if (self.last_error == null) try self.setError("File is closed");
            return false;
        }
        if (!self.readable) {
            try self.setError("File not open for reading");
            return false;
        }
        return true;
    }

    fn ensureOpenForWrite(self: *FileState) !bool {
        if (self.handle == null) {
            if (self.last_error == null) try self.setError("File is closed");
            return false;
        }
        if (!self.writable) {
            try self.setError("File not open for writing");
            return false;
        }
        return true;
    }
};

const ModePlan = struct {
    readable: bool,
    writable: bool,
    append: bool,
    create: bool,
    truncate: bool,
    read_access: bool,
    open_mode: std.Io.Dir.OpenFileOptions.Mode,
};

fn parseMode(mode_text: []const u8) !ModePlan {
    var base: ?u8 = null;
    var plus = false;

    for (mode_text) |ch| {
        switch (std.ascii.toLower(ch)) {
            'r', 'w', 'a' => {
                if (base != null) return error.InvalidMode;
                base = std.ascii.toLower(ch);
            },
            '+' => plus = true,
            'b', 't' => {},
            else => return error.InvalidMode,
        }
    }

    const base_mode = base orelse return error.InvalidMode;
    return switch (base_mode) {
        'r' => .{
            .readable = true,
            .writable = plus,
            .append = false,
            .create = false,
            .truncate = false,
            .read_access = false,
            .open_mode = if (plus) .read_write else .read_only,
        },
        'w' => .{
            .readable = plus,
            .writable = true,
            .append = false,
            .create = true,
            .truncate = true,
            .read_access = plus,
            .open_mode = .write_only,
        },
        'a' => .{
            .readable = plus,
            .writable = true,
            .append = true,
            .create = true,
            .truncate = false,
            .read_access = plus,
            .open_mode = .write_only,
        },
        else => return error.InvalidMode,
    };
}

fn openPath(io: std.Io, path: []const u8, mode: std.Io.Dir.OpenFileOptions.Mode) !std.Io.File {
    const opts = std.Io.Dir.OpenFileOptions{
        .mode = mode,
        .allow_directory = false,
    };
    if (std.fs.path.isAbsolute(path)) {
        return std.Io.Dir.openFileAbsolute(io, path, opts);
    }
    return std.Io.Dir.cwd().openFile(io, path, opts);
}

fn createPath(io: std.Io, path: []const u8, read_access: bool, truncate: bool) !std.Io.File {
    const flags = std.Io.Dir.CreateFileOptions{
        .read = read_access,
        .truncate = truncate,
    };
    if (std.fs.path.isAbsolute(path)) {
        return std.Io.Dir.createFileAbsolute(io, path, flags);
    }
    return std.Io.Dir.cwd().createFile(io, path, flags);
}

pub fn createState(allocator: std.mem.Allocator, io: std.Io, path: []const u8, mode_text: []const u8) Error!*FileState {
    const stored_mode = if (mode_text.len == 0) "r" else mode_text;
    var state = try allocator.create(FileState);
    var name_owned = false;
    var mode_owned = false;
    state.* = .{
        .allocator = allocator,
        .name = "",
        .mode = "",
    };
    errdefer {
        if (state.handle) |file| file.close(io);
        if (state.last_error) |err| state.allocator.free(err);
        if (mode_owned) state.allocator.free(state.mode);
        if (name_owned) state.allocator.free(state.name);
        allocator.destroy(state);
    }

    state.name = try allocator.dupe(u8, path);
    name_owned = true;
    state.mode = try allocator.dupe(u8, stored_mode);
    mode_owned = true;

    const plan = parseMode(stored_mode) catch {
        try state.setError("Invalid open mode");
        return state;
    };
    state.readable = plan.readable;
    state.writable = plan.writable;
    state.append = plan.append;

    const file = (if (plan.create)
        createPath(io, path, plan.read_access, plan.truncate)
    else
        openPath(io, path, plan.open_mode)) catch |err| {
        try state.setErrorFromAnyError(err);
        return state;
    };

    state.handle = file;
    if (plan.append) {
        const st = file.stat(io) catch |err| {
            try state.setErrorFromAnyError(err);
            return state;
        };
        if (st.kind == .file) {
            state.read_pos = st.size;
            state.write_pos = st.size;
        }
    }

    return state;
}

pub fn object(state: *FileState) value.ObjectValue {
    return .{ .kind = .file, .ptr = state };
}

pub fn deinitObject(allocator: std.mem.Allocator, io: std.Io, object_value: value.ObjectValue) void {
    const state = @as(*FileState, @ptrCast(@alignCast(object_value.ptr)));
    state.deinit(allocator, io);
}

fn emptyString(allocator: std.mem.Allocator) ![]u8 {
    return allocator.dupe(u8, "");
}

fn currentSize(self: *const FileState, io: std.Io) ?u64 {
    const file = self.handle orelse return null;
    const st = file.stat(io) catch return null;
    if (st.kind != .file) return null;
    return st.size;
}

fn appendChunk(
    out: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    chunk: []const u8,
    saw_null: *bool,
) !void {
    if (saw_null.*) return;
    for (chunk) |byte| {
        if (byte == 0) {
            saw_null.* = true;
            break;
        }
        try out.append(allocator, byte);
    }
}

pub fn read(self: *FileState, allocator: std.mem.Allocator, io: std.Io, count: ?usize) ![]u8 {
    if (!try self.ensureOpenForRead()) return try emptyString(allocator);
    const file = self.handle.?;

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    var offset = self.read_pos;
    var remaining = count;
    var chunk: [4096]u8 = undefined;
    var saw_null = false;

    while (true) {
        const want = if (remaining) |remaining_count| @min(remaining_count, chunk.len) else chunk.len;
        if (want == 0) break;

        const got = file.readPositionalAll(io, chunk[0..want], offset) catch |err| {
            try self.setErrorFromAnyError(err);
            return try emptyString(allocator);
        };
        if (got == 0) break;

        try appendChunk(&out, allocator, chunk[0..got], &saw_null);
        offset += got;

        if (remaining) |*remaining_count| {
            if (got >= remaining_count.*) {
                remaining_count.* = 0;
                break;
            }
            remaining_count.* -= got;
        } else if (got < want) {
            break;
        }
    }

    self.read_pos = offset;
    self.clearError();
    return try out.toOwnedSlice(allocator);
}

pub fn readLine(self: *FileState, allocator: std.mem.Allocator, io: std.Io) ![]u8 {
    if (!try self.ensureOpenForRead()) return try emptyString(allocator);
    const file = self.handle.?;

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    var offset = self.read_pos;
    var chunk: [256]u8 = undefined;
    var saw_null = false;

    while (true) {
        const got = file.readPositionalAll(io, chunk[0..], offset) catch |err| {
            try self.setErrorFromAnyError(err);
            return try emptyString(allocator);
        };
        if (got == 0) break;

        var consumed: usize = 0;
        while (consumed < got) : (consumed += 1) {
            const byte = chunk[consumed];
            if (byte == '\n') {
                if (out.items.len > 0 and out.items[out.items.len - 1] == '\r') {
                    _ = out.pop();
                }
                offset += consumed + 1;
                self.read_pos = offset;
                self.clearError();
                return try out.toOwnedSlice(allocator);
            }
            if (!saw_null) {
                if (byte == 0) {
                    saw_null = true;
                } else {
                    try out.append(allocator, byte);
                }
            }
        }

        offset += got;
        if (got < chunk.len) break;
    }

    self.read_pos = offset;
    self.clearError();
    return try out.toOwnedSlice(allocator);
}

pub fn write(self: *FileState, allocator: std.mem.Allocator, io: std.Io, bytes: []const u8, length: usize) !i64 {
    _ = allocator;
    if (length == 0) return 0;
    if (!try self.ensureOpenForWrite()) return 0;
    const file = self.handle.?;
    const end = @min(length, bytes.len);
    const slice = bytes[0..end];

    file.writePositionalAll(io, slice, self.write_pos) catch |err| {
        try self.setErrorFromAnyError(err);
        return 0;
    };

    self.write_pos += slice.len;
    self.clearError();
    return @intCast(slice.len);
}

pub fn eof(self: *const FileState, io: std.Io) bool {
    const size = currentSize(self, io) orelse return true;
    return self.read_pos >= size;
}

pub fn rewind(self: *FileState, allocator: std.mem.Allocator) void {
    _ = allocator;
    if (self.handle == null) return;
    self.read_pos = 0;
    self.clearError();
}

pub fn close(self: *FileState, allocator: std.mem.Allocator, io: std.Io) void {
    _ = allocator;
    if (self.handle) |file| {
        file.close(io);
        self.handle = null;
        self.clearError();
    }
}

pub fn errorValue(self: *const FileState) value.Value {
    if (self.last_error) |err| return .{ .string = err };
    return .{ .none = {} };
}

pub fn nameValue(self: *const FileState) value.Value {
    return .{ .string = self.name };
}

pub fn modeValue(self: *const FileState) value.Value {
    return .{ .string = self.mode };
}

fn errorMessage(err: anyerror) []const u8 {
    return switch (err) {
        error.FileNotFound => "No such file or directory",
        error.AccessDenied => "Permission denied",
        error.PermissionDenied => "Permission denied",
        error.IsDir => "Is a directory",
        error.NotDir => "Not a directory",
        error.PathAlreadyExists => "File exists",
        error.NameTooLong => "File name too long",
        error.WouldBlock => "Operation would block",
        error.NotOpenForReading => "File not open for reading",
        error.NotOpenForWriting => "File not open for writing",
        error.Unseekable => "File is unseekable",
        else => @errorName(err),
    };
}

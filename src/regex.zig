const std = @import("std");

const c = @cImport({
    @cDefine("PCRE2_CODE_UNIT_WIDTH", "8");
    @cInclude("pcre2.h");
});

pub const Error = error{
    InvalidPattern,
    OutOfMemory,
};

const pcre2_code = c.pcre2_code_8;
const pcre2_match_data = c.pcre2_match_data_8;

const PCRE2_ERROR_NOMATCH: c_int = c.PCRE2_ERROR_NOMATCH;
const PCRE2_ERROR_NOMEMORY: c_int = c.PCRE2_ERROR_NOMEMORY;
const PCRE2_UNSET: usize = std.math.maxInt(usize);
const BYTE_DOLLAR: u8 = 36;
const BYTE_OPEN_BRACE: u8 = 123;
const BYTE_CLOSE_BRACE: u8 = 125;
const BYTE_ZERO: u8 = 48;
const BYTE_NINE: u8 = 57;

fn compilePattern(pattern: []const u8) Error!*pcre2_code {
    var errcode: c_int = 0;
    var erroffset: usize = 0;
    const pattern_ptr: [*c]const u8 = @ptrCast(pattern.ptr);
    const code = c.pcre2_compile_8(pattern_ptr, pattern.len, 0, &errcode, &erroffset, null) orelse {
        if (errcode == PCRE2_ERROR_NOMEMORY) return error.OutOfMemory;
        return error.InvalidPattern;
    };
    return code;
}

pub fn isValid(pattern: []const u8) Error!bool {
    const code = compilePattern(pattern) catch |err| switch (err) {
        error.InvalidPattern => return false,
        else => return err,
    };
    defer c.pcre2_code_free_8(code);
    return true;
}

fn appendCapture(
    out: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    subject: []const u8,
    ovector: [*c]usize,
    capture_count: usize,
    group_number: usize,
) !void {
    if (group_number >= capture_count) return;
    const base = group_number * 2;
    const start = ovector[base];
    const end = ovector[base + 1];
    if (start == PCRE2_UNSET or end == PCRE2_UNSET or end < start or end > subject.len) return;
    try out.appendSlice(allocator, subject[start..end]);
}

fn appendReplacementToken(
    out: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    code: *pcre2_code,
    subject: []const u8,
    ovector: [*c]usize,
    capture_count: usize,
    token: []const u8,
) Error!void {
    if (token.len == 0) return;

    if (std.ascii.isDigit(token[0])) {
        const group_number = std.fmt.parseInt(usize, token, 10) catch return;
        try appendCapture(out, allocator, subject, ovector, capture_count, group_number);
        return;
    }

    const c_name = try allocator.alloc(u8, token.len + 1);
    defer allocator.free(c_name);
    @memcpy(c_name[0..token.len], token);
    c_name[token.len] = 0;
    const group = c.pcre2_substring_number_from_name_8(code, c_name.ptr);
    if (group <= 0) return;
    try appendCapture(out, allocator, subject, ovector, capture_count, @as(usize, @intCast(group)));
}

fn appendReplacement(
    out: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    code: *pcre2_code,
    subject: []const u8,
    ovector: [*c]usize,
    capture_count: usize,
    replacement: []const u8,
) Error!void {
    var i: usize = 0;
    while (i < replacement.len) {
        if (replacement[i] != BYTE_DOLLAR) {
            try out.append(allocator, replacement[i]);
            i += 1;
            continue;
        }

        if (i + 1 >= replacement.len) {
            try out.append(allocator, BYTE_DOLLAR);
            break;
        }

        switch (replacement[i + 1]) {
            BYTE_DOLLAR => {
                try out.append(allocator, BYTE_DOLLAR);
                i += 2;
            },
            BYTE_OPEN_BRACE => {
                const rest = replacement[i + 2 ..];
                const close = std.mem.indexOfScalar(u8, rest, BYTE_CLOSE_BRACE) orelse {
                    try out.append(allocator, BYTE_DOLLAR);
                    i += 1;
                    continue;
                };
                const token = std.mem.trim(u8, rest[0..close], " \t\r\n");
                try appendReplacementToken(out, allocator, code, subject, ovector, capture_count, token);
                i += close + 3;
            },
            BYTE_ZERO...BYTE_NINE => {
                var end: usize = i + 1;
                while (end < replacement.len and std.ascii.isDigit(replacement[end])) : (end += 1) {}
                try appendReplacementToken(out, allocator, code, subject, ovector, capture_count, replacement[i + 1 .. end]);
                i = end;
            },
            else => {
                try out.append(allocator, BYTE_DOLLAR);
                i += 1;
            },
        }
    }
}

fn resolveGroupNumber(
    allocator: std.mem.Allocator,
    code: *pcre2_code,
    selector: []const u8,
) Error!?usize {
    if (selector.len == 0) return 0;

    if (std.fmt.parseInt(usize, selector, 10)) |group_number| {
        return group_number;
    } else |_| {}

    const c_name = try allocator.alloc(u8, selector.len + 1);
    defer allocator.free(c_name);
    @memcpy(c_name[0..selector.len], selector);
    c_name[selector.len] = 0;

    const group = c.pcre2_substring_number_from_name_8(code, c_name.ptr);
    if (group <= 0) return null;
    return @as(usize, @intCast(group));
}

pub fn isMatch(allocator: std.mem.Allocator, pattern: []const u8, subject: []const u8) Error!bool {
    _ = allocator;
    const code = try compilePattern(pattern);
    defer c.pcre2_code_free_8(code);

    const match_data = c.pcre2_match_data_create_from_pattern_8(code, null) orelse return error.OutOfMemory;
    defer c.pcre2_match_data_free_8(match_data);

    const subject_ptr: [*c]const u8 = @ptrCast(subject.ptr);
    const rc = c.pcre2_match_8(code, subject_ptr, subject.len, 0, 0, match_data, null);
    if (rc == PCRE2_ERROR_NOMATCH) return false;
    if (rc < 0) return error.InvalidPattern;
    return true;
}

pub fn extractFirst(
    allocator: std.mem.Allocator,
    pattern: []const u8,
    subject: []const u8,
    group_selector: ?[]const u8,
) Error![]u8 {
    const code = try compilePattern(pattern);
    defer c.pcre2_code_free_8(code);

    const match_data = c.pcre2_match_data_create_from_pattern_8(code, null) orelse return error.OutOfMemory;
    defer c.pcre2_match_data_free_8(match_data);

    const subject_ptr: [*c]const u8 = @ptrCast(subject.ptr);
    const rc = c.pcre2_match_8(code, subject_ptr, subject.len, 0, 0, match_data, null);
    if (rc == PCRE2_ERROR_NOMATCH) return allocator.dupe(u8, "");
    if (rc < 0) return error.InvalidPattern;

    const ovector = c.pcre2_get_ovector_pointer_8(match_data);
    const capture_count: usize = @intCast(rc);
    const group_number = if (group_selector) |selector|
        (try resolveGroupNumber(allocator, code, selector)) orelse return allocator.dupe(u8, "")
    else
        0;

    if (group_number >= capture_count) return allocator.dupe(u8, "");
    const base = group_number * 2;
    const start = ovector[base];
    const end = ovector[base + 1];
    if (start == PCRE2_UNSET or end == PCRE2_UNSET or end < start or end > subject.len) {
        return allocator.dupe(u8, "");
    }
    return allocator.dupe(u8, subject[start..end]);
}

pub fn replaceAll(
    allocator: std.mem.Allocator,
    pattern: []const u8,
    replacement: []const u8,
    subject: []const u8,
) Error![]u8 {
    const code = try compilePattern(pattern);
    defer c.pcre2_code_free_8(code);

    const match_data = c.pcre2_match_data_create_from_pattern_8(code, null) orelse return error.OutOfMemory;
    defer c.pcre2_match_data_free_8(match_data);

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    const subject_ptr: [*c]const u8 = @ptrCast(subject.ptr);
    var search_offset: usize = 0;
    var last_emit: usize = 0;

    while (search_offset <= subject.len) {
        const rc = c.pcre2_match_8(code, subject_ptr, subject.len, search_offset, 0, match_data, null);
        if (rc == PCRE2_ERROR_NOMATCH) {
            try out.appendSlice(allocator, subject[last_emit..]);
            last_emit = subject.len;
            break;
        }
        if (rc < 0) return error.InvalidPattern;

        const ovector = c.pcre2_get_ovector_pointer_8(match_data);
        const capture_count: usize = @intCast(rc);
        const start = ovector[0];
        const end = ovector[1];
        if (start < last_emit or end < start or end > subject.len) return error.InvalidPattern;

        try out.appendSlice(allocator, subject[last_emit..start]);
        try appendReplacement(&out, allocator, code, subject, ovector, capture_count, replacement);
        last_emit = end;

        if (end == start) {
            if (search_offset >= subject.len) break;
            search_offset = start + 1;
        } else {
            search_offset = end;
        }
    }

    if (last_emit < subject.len) {
        try out.appendSlice(allocator, subject[last_emit..]);
    }

    return try out.toOwnedSlice(allocator);
}

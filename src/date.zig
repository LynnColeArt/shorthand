const std = @import("std");

const epoch = std.time.epoch;

pub const Error = error{
    InvalidDate,
    OutOfMemory,
};

const day_seconds: i64 = 24 * 60 * 60;

const weekday_abbrev = [_][]const u8{ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" };
const weekday_full = [_][]const u8{ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" };
const month_abbrev = [_][]const u8{ "", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };
const month_full = [_][]const u8{ "", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" };

const Group = struct {
    value: i64,
    len: usize,
};

pub const DateParts = struct {
    year: i32,
    month: u8,
    day: u8,
    hour: u8,
    minute: u8,
    second: u8,
    weekday: u8,
    yearday: u16,
};

fn daysInYear(year: i32) i64 {
    return @as(i64, @intCast(epoch.getDaysInYear(@as(epoch.Year, @intCast(year)))));
}

fn daysInMonth(year: i32, month: u8) i64 {
    return @as(i64, @intCast(epoch.getDaysInMonth(@as(epoch.Year, @intCast(year)), @as(epoch.Month, @enumFromInt(month)))));
}

fn currentCentury(year: i32) i32 {
    return @divTrunc(year, 100) * 100;
}

fn parseUnsigned(text: []const u8) Error!i64 {
    return std.fmt.parseInt(i64, text, 10) catch error.InvalidDate;
}

fn scanGroups(text: []const u8, groups: *[4]Group) Error!usize {
    var count: usize = 0;
    var i: usize = 0;
    while (i < text.len) {
        while (i < text.len and !std.ascii.isDigit(text[i])) : (i += 1) {}
        if (i >= text.len) break;
        const start = i;
        while (i < text.len and std.ascii.isDigit(text[i])) : (i += 1) {}
        if (count >= groups.len) return error.InvalidDate;
        groups[count] = .{
            .value = try parseUnsigned(text[start..i]),
            .len = i - start,
        };
        count += 1;
    }
    return count;
}

fn validateDateParts(year: i32, month: i64, day: i64, hour: i64, minute: i64, second: i64) Error!void {
    if (year < 2 or year > 9999) return error.InvalidDate;
    if (month < 1 or month > 12) return error.InvalidDate;
    const max_day = daysInMonth(year, @as(u8, @intCast(month)));
    if (day < 1 or day > max_day) return error.InvalidDate;
    if (hour < 0 or hour > 23) return error.InvalidDate;
    if (minute < 0 or minute > 59) return error.InvalidDate;
    if (second < 0 or second > 59) return error.InvalidDate;
}

fn dayCountBeforeYear(year: i32) i64 {
    var days: i64 = 0;
    if (year >= 1970) {
        var y: i32 = 1970;
        while (y < year) : (y += 1) {
            days += daysInYear(y);
        }
    } else {
        var y: i32 = year;
        while (y < 1970) : (y += 1) {
            days -= daysInYear(y);
        }
    }
    return days;
}

fn dayOfYear(year: i32, month: u8, day: u8) i64 {
    var yday: i64 = 0;
    var m: u8 = 1;
    while (m < month) : (m += 1) {
        yday += daysInMonth(year, m);
    }
    return yday + @as(i64, day) - 1;
}

pub fn encodeDateTime(year: i32, month: i64, day: i64, hour: i64, minute: i64, second: i64) Error!i64 {
    try validateDateParts(year, month, day, hour, minute, second);
    const month_u8 = @as(u8, @intCast(month));
    const day_u8 = @as(u8, @intCast(day));
    const days = dayCountBeforeYear(year) + dayOfYear(year, month_u8, day_u8);
    return (days * day_seconds) + (@as(i64, hour) * 3600) + (@as(i64, minute) * 60) + second;
}

pub fn decodeEpochSeconds(secs: i64) Error!DateParts {
    const epoch_days = @divFloor(secs, day_seconds);
    var second_of_day = @mod(secs, day_seconds);
    if (second_of_day < 0) {
        second_of_day += day_seconds;
    }

    var year: i32 = 1970;
    var day_in_year: i64 = epoch_days;
    if (day_in_year >= 0) {
        while (true) {
            const ydays = daysInYear(year);
            if (day_in_year < ydays) break;
            day_in_year -= ydays;
            year += 1;
            if (year > 9999) return error.InvalidDate;
        }
    } else {
        while (day_in_year < 0) {
            year -= 1;
            if (year < 2) return error.InvalidDate;
            day_in_year += daysInYear(year);
        }
    }

    var month: u8 = 1;
    var day_of_month: i64 = day_in_year;
    while (true) {
        const month_days = daysInMonth(year, month);
        if (day_of_month < month_days) break;
        day_of_month -= month_days;
        month += 1;
    }

    const weekday_raw = @mod(epoch_days + 4, 7);
    const weekday = @as(u8, @intCast(if (weekday_raw < 0) weekday_raw + 7 else weekday_raw));

    return .{
        .year = year,
        .month = month,
        .day = @as(u8, @intCast(day_of_month + 1)),
        .hour = @as(u8, @intCast(@divTrunc(second_of_day, 3600))),
        .minute = @as(u8, @intCast(@divTrunc(@mod(second_of_day, 3600), 60))),
        .second = @as(u8, @intCast(@mod(second_of_day, 60))),
        .weekday = weekday,
        .yearday = @as(u16, @intCast(day_in_year)),
    };
}

fn currentCenturyFromSeconds(current_seconds: i64) i32 {
    const parts = decodeEpochSeconds(current_seconds) catch return 2000;
    return currentCentury(parts.year);
}

fn parseTimestampDigits(text: []const u8, current_seconds: i64) Error!i64 {
    const current_century = currentCenturyFromSeconds(current_seconds);
    return switch (text.len) {
        14 => encodeDateTime(
            @as(i32, @intCast(try parseUnsigned(text[0..4]))),
            try parseUnsigned(text[4..6]),
            try parseUnsigned(text[6..8]),
            try parseUnsigned(text[8..10]),
            try parseUnsigned(text[10..12]),
            try parseUnsigned(text[12..14]),
        ),
        12 => encodeDateTime(
            current_century + @as(i32, @intCast(try parseUnsigned(text[0..2]))),
            try parseUnsigned(text[2..4]),
            try parseUnsigned(text[4..6]),
            try parseUnsigned(text[6..8]),
            try parseUnsigned(text[8..10]),
            try parseUnsigned(text[10..12]),
        ),
        10 => encodeDateTime(
            current_century + @as(i32, @intCast(try parseUnsigned(text[0..2]))),
            try parseUnsigned(text[2..4]),
            try parseUnsigned(text[4..6]),
            try parseUnsigned(text[6..8]),
            try parseUnsigned(text[8..10]),
            0,
        ),
        8 => encodeDateTime(
            @as(i32, @intCast(try parseUnsigned(text[0..4]))),
            try parseUnsigned(text[4..6]),
            try parseUnsigned(text[6..8]),
            0,
            0,
            0,
        ),
        6 => encodeDateTime(
            current_century + @as(i32, @intCast(try parseUnsigned(text[0..2]))),
            try parseUnsigned(text[2..4]),
            try parseUnsigned(text[4..6]),
            0,
            0,
            0,
        ),
        4 => encodeDateTime(
            current_century + @as(i32, @intCast(try parseUnsigned(text[0..2]))),
            try parseUnsigned(text[2..4]),
            1,
            0,
            0,
            0,
        ),
        2 => encodeDateTime(
            current_century + @as(i32, @intCast(try parseUnsigned(text[0..2]))),
            1,
            1,
            0,
            0,
            0,
        ),
        else => error.InvalidDate,
    };
}

fn parseDateGroups(text: []const u8, current_seconds: i64) Error!i64 {
    var groups: [4]Group = undefined;
    const group_count = try scanGroups(text, &groups);
    if (group_count != 3) return error.InvalidDate;

    const current_century = currentCenturyFromSeconds(current_seconds);
    const year = if (groups[0].len <= 2)
        current_century + @as(i32, @intCast(groups[0].value))
    else
        @as(i32, @intCast(groups[0].value));

    return encodeDateTime(year, groups[1].value, groups[2].value, 0, 0, 0);
}

fn parseTimeGroups(text: []const u8, current_seconds: i64) Error!i64 {
    var groups: [4]Group = undefined;
    const group_count = try scanGroups(text, &groups);
    if (group_count < 2 or group_count > 3) return error.InvalidDate;

    const current = decodeEpochSeconds(current_seconds) catch return error.InvalidDate;
    const second_value = if (group_count == 3) groups[2].value else 0;
    return encodeDateTime(current.year, current.month, current.day, groups[0].value, groups[1].value, second_value);
}

fn isTimeLike(text: []const u8, groups: []const Group) bool {
    if (std.mem.indexOfScalar(u8, text, ':') == null) return false;
    if (groups.len < 2 or groups.len > 3) return false;
    if (groups[0].value > 23 or groups[1].value > 59) return false;
    if (groups.len == 3 and groups[2].value > 59) return false;
    return true;
}

pub fn parseText(text: []const u8, current_seconds: i64) Error!i64 {
    const trimmed = std.mem.trim(u8, text, " \t\r\n");
    if (trimmed.len == 0) return error.InvalidDate;

    var all_digits = true;
    for (trimmed) |ch| {
        if (!std.ascii.isDigit(ch)) {
            all_digits = false;
            break;
        }
    }
    if (all_digits) return parseTimestampDigits(trimmed, current_seconds);

    if (std.mem.indexOfAny(u8, trimmed, " \t\r\n")) |space_index| {
        const first = std.mem.trim(u8, trimmed[0..space_index], " \t\r\n");
        const rest = std.mem.trim(u8, trimmed[space_index..], " \t\r\n");
        var rest_it = std.mem.tokenizeAny(u8, rest, " \t\r\n");
        const second = rest_it.next() orelse return error.InvalidDate;
        if (rest_it.next() != null) return error.InvalidDate;

        var groups: [4]Group = undefined;
        if (try scanGroups(first, &groups) != 3) return error.InvalidDate;
        const current_century = currentCenturyFromSeconds(current_seconds);
        const year = if (groups[0].len <= 2)
            current_century + @as(i32, @intCast(groups[0].value))
        else
            @as(i32, @intCast(groups[0].value));
        const date_seconds = try encodeDateTime(year, groups[1].value, groups[2].value, 0, 0, 0);
        const date_parts = try decodeEpochSeconds(date_seconds);
        const time_seconds = try parseTimeGroups(second, current_seconds);
        const time_parts = try decodeEpochSeconds(time_seconds);
        return encodeDateTime(date_parts.year, date_parts.month, date_parts.day, time_parts.hour, time_parts.minute, time_parts.second);
    }

    var groups: [4]Group = undefined;
    const group_count = try scanGroups(trimmed, &groups);
    if (isTimeLike(trimmed, groups[0..group_count])) {
        return parseTimeGroups(trimmed, current_seconds);
    }
    if (group_count == 3) {
        return parseDateGroups(trimmed, current_seconds);
    }

    return error.InvalidDate;
}

fn appendSlice(out: *std.ArrayList(u8), allocator: std.mem.Allocator, slice: []const u8) Error!void {
    try out.appendSlice(allocator, slice);
}

fn appendChar(out: *std.ArrayList(u8), allocator: std.mem.Allocator, ch: u8) Error!void {
    try out.append(allocator, ch);
}

fn appendInt(out: *std.ArrayList(u8), allocator: std.mem.Allocator, value: anytype) Error!void {
    var buf: [32]u8 = undefined;
    const slice = std.fmt.bufPrint(&buf, "{d}", .{value}) catch unreachable;
    try out.appendSlice(allocator, slice);
}

fn appendPadded(out: *std.ArrayList(u8), allocator: std.mem.Allocator, value: anytype, width: usize) Error!void {
    var buf: [32]u8 = undefined;
    const unsigned_value = @as(u64, @intCast(value));
    const slice = switch (width) {
        2 => std.fmt.bufPrint(&buf, "{d:0>2}", .{unsigned_value}) catch unreachable,
        3 => std.fmt.bufPrint(&buf, "{d:0>3}", .{unsigned_value}) catch unreachable,
        4 => std.fmt.bufPrint(&buf, "{d:0>4}", .{unsigned_value}) catch unreachable,
        else => std.fmt.bufPrint(&buf, "{d}", .{unsigned_value}) catch unreachable,
    };
    try out.appendSlice(allocator, slice);
}

fn monthIndex(parts: DateParts) usize {
    return @as(usize, parts.month);
}

fn weekdayIndex(parts: DateParts) usize {
    return @as(usize, parts.weekday);
}

fn lowerHour(parts: DateParts) u8 {
    var hour = parts.hour % 12;
    if (hour == 0) hour = 12;
    return hour;
}

pub fn formatDate(allocator: std.mem.Allocator, epoch_seconds: i64, format_text: []const u8) Error![]u8 {
    const parts = try decodeEpochSeconds(epoch_seconds);

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    var i: usize = 0;
    while (i < format_text.len) {
        if (format_text[i] != '%') {
            try appendChar(&out, allocator, format_text[i]);
            i += 1;
            continue;
        }

        const token_start = i;
        i += 1;
        if (i >= format_text.len) {
            try appendChar(&out, allocator, '%');
            break;
        }

        const suppress_zero = if (format_text[i] == '#') blk: {
            i += 1;
            if (i >= format_text.len) {
                try appendChar(&out, allocator, '%');
                break :blk false;
            }
            break :blk true;
        } else false;

        const spec = format_text[i];
        i += 1;

        switch (spec) {
            '%' => try appendChar(&out, allocator, '%'),
            'a' => try appendSlice(&out, allocator, weekday_abbrev[weekdayIndex(parts)]),
            'A' => try appendSlice(&out, allocator, weekday_full[weekdayIndex(parts)]),
            'b' => try appendSlice(&out, allocator, month_abbrev[monthIndex(parts)]),
            'B' => try appendSlice(&out, allocator, month_full[monthIndex(parts)]),
            'c' => {
                try appendSlice(&out, allocator, weekday_abbrev[weekdayIndex(parts)]);
                try appendChar(&out, allocator, ' ');
                try appendSlice(&out, allocator, month_abbrev[monthIndex(parts)]);
                try appendChar(&out, allocator, ' ');
                try appendPadded(&out, allocator, parts.day, 2);
                try appendChar(&out, allocator, ' ');
                try appendPadded(&out, allocator, parts.hour, 2);
                try appendChar(&out, allocator, ':');
                try appendPadded(&out, allocator, parts.minute, 2);
                try appendChar(&out, allocator, ':');
                try appendPadded(&out, allocator, parts.second, 2);
                try appendChar(&out, allocator, ' ');
                try appendPadded(&out, allocator, parts.year, 4);
            },
            'd' => if (suppress_zero) try appendInt(&out, allocator, parts.day) else try appendPadded(&out, allocator, parts.day, 2),
            'H' => if (suppress_zero) try appendInt(&out, allocator, parts.hour) else try appendPadded(&out, allocator, parts.hour, 2),
            'I' => if (suppress_zero) try appendInt(&out, allocator, lowerHour(parts)) else try appendPadded(&out, allocator, lowerHour(parts), 2),
            'j' => if (suppress_zero) try appendInt(&out, allocator, parts.yearday + 1) else try appendPadded(&out, allocator, parts.yearday + 1, 3),
            'm' => if (suppress_zero) try appendInt(&out, allocator, parts.month) else try appendPadded(&out, allocator, parts.month, 2),
            'M' => if (suppress_zero) try appendInt(&out, allocator, parts.minute) else try appendPadded(&out, allocator, parts.minute, 2),
            'p' => try appendSlice(&out, allocator, if (parts.hour < 12) "AM" else "PM"),
            'S' => if (suppress_zero) try appendInt(&out, allocator, parts.second) else try appendPadded(&out, allocator, parts.second, 2),
            'U' => {
                const week = @as(u16, @intCast((parts.yearday + 7 - parts.weekday) / 7));
                if (suppress_zero) try appendInt(&out, allocator, week) else try appendPadded(&out, allocator, week, 2);
            },
            'w' => try appendInt(&out, allocator, parts.weekday),
            'W' => {
                const weekday_monday = @as(u16, @intCast((parts.weekday + 6) % 7));
                const week = @as(u16, @intCast((parts.yearday + 7 - weekday_monday) / 7));
                if (suppress_zero) try appendInt(&out, allocator, week) else try appendPadded(&out, allocator, week, 2);
            },
            'x' => {
                try appendPadded(&out, allocator, parts.month, 2);
                try appendChar(&out, allocator, '/');
                try appendPadded(&out, allocator, parts.day, 2);
                try appendChar(&out, allocator, '/');
                try appendPadded(&out, allocator, @mod(parts.year, 100), 2);
            },
            'y' => if (suppress_zero) try appendInt(&out, allocator, @mod(parts.year, 100)) else try appendPadded(&out, allocator, @mod(parts.year, 100), 2),
            'Y' => if (suppress_zero) try appendInt(&out, allocator, parts.year) else try appendPadded(&out, allocator, parts.year, 4),
            'z' => try appendSlice(&out, allocator, "+0000"),
            'Z' => try appendSlice(&out, allocator, "GMT"),
            else => try out.appendSlice(allocator, format_text[token_start..i]),
        }
    }

    return try out.toOwnedSlice(allocator);
}

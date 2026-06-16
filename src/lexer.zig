const std = @import("std");
const ast = @import("ast.zig");

pub const Error = error{
    UnterminatedScriptBlock,
};

const TagInfo = struct {
    style: ast.TagStyle,
    kind: ast.ScriptKind,
    open_len: usize,
    close: []const u8,
};

pub const Lexer = struct {
    source: []const u8,
    index: usize = 0,

    pub fn init(source: []const u8) Lexer {
        return .{ .source = source };
    }

    pub fn reset(self: *Lexer) void {
        self.index = 0;
    }

    pub fn eof(self: *const Lexer) bool {
        return self.index >= self.source.len;
    }

    pub fn nextChunk(self: *Lexer) Error!?ast.Chunk {
        if (self.eof()) return null;

        if (self.openTagAt(self.index)) |tag| {
            const body_start = self.index + tag.open_len;
            const body_end = try self.findScriptBodyEnd(body_start, tag.close);
            self.index = body_end + tag.close.len;
            return .{
                .script = .{
                    .span = .{ .start = body_start, .end = body_end },
                    .style = tag.style,
                    .kind = tag.kind,
                },
            };
        }

        const text_start = self.index;
        while (self.index < self.source.len) {
            if (self.openTagAt(self.index) != null) break;
            self.index += 1;
        }
        return .{ .text = .{ .start = text_start, .end = self.index } };
    }

    fn openTagAt(self: *const Lexer, index: usize) ?TagInfo {
        if (index + 1 >= self.source.len) return null;
        if (self.source[index] != '<') return null;

        const marker = self.source[index + 1];
        const kind: ast.ScriptKind = if (index + 2 < self.source.len) switch (marker) {
            '~' => if (self.source[index + 2] == '@') .expr else .block,
            '%' => if (self.source[index + 2] == '=') .expr else .block,
            '?' => if (self.source[index + 2] == '=') .expr else .block,
            else => return null,
        } else switch (marker) {
            '~', '%', '?' => .block,
            else => return null,
        };

        const style: ast.TagStyle = switch (marker) {
            '~' => .tilde,
            '%' => .percent,
            '?' => .question,
            else => return null,
        };
        const open_len: usize = if (kind == .expr) 3 else 2;
        const close: []const u8 = switch (marker) {
            '~' => "~>",
            '%' => "%>",
            '?' => "?>",
            else => unreachable,
        };
        return .{
            .style = style,
            .kind = kind,
            .open_len = open_len,
            .close = close,
        };
    }

    fn findScriptBodyEnd(self: *const Lexer, start: usize, close: []const u8) Error!usize {
        var i = start;
        var in_single_quote = false;
        var in_double_quote = false;

        while (i < self.source.len) {
            if (!in_single_quote and !in_double_quote and std.mem.startsWith(u8, self.source[i..], close)) {
                return i;
            }

            const c = self.source[i];
            if (in_single_quote) {
                if (c == '\\' and i + 1 < self.source.len) {
                    i += 2;
                    continue;
                }
                if (c == '\'') {
                    in_single_quote = false;
                }
                i += 1;
                continue;
            }

            if (in_double_quote) {
                if (c == '\\' and i + 1 < self.source.len) {
                    i += 2;
                    continue;
                }
                if (c == '"') {
                    in_double_quote = false;
                }
                i += 1;
                continue;
            }

            switch (c) {
                '"' => {
                    in_double_quote = true;
                    i += 1;
                },
                '\'' => {
                    if (self.looksLikeSingleQuotedString(i)) {
                        in_single_quote = true;
                    }
                    i += 1;
                },
                else => i += 1,
            }
        }

        return error.UnterminatedScriptBlock;
    }

    fn looksLikeSingleQuotedString(self: *const Lexer, index: usize) bool {
        var i = index + 1;
        while (i < self.source.len) {
            const c = self.source[i];
            if (c == '\n' or c == '\r') return false;
            if (c == '\\' and i + 1 < self.source.len) {
                i += 2;
                continue;
            }
            if (c == '\'') return true;
            i += 1;
        }
        return false;
    }
};

pub fn writeRaw(writer: anytype, text: []const u8) !void {
    try writer.writeAll(text);
}

pub fn escapeHtml(writer: anytype, text: []const u8) !void {
    for (text) |c| {
        switch (c) {
            '&' => try writer.writeAll("&amp;"),
            '<' => try writer.writeAll("&lt;"),
            '>' => try writer.writeAll("&gt;"),
            '"' => try writer.writeAll("&quot;"),
            '\'' => try writer.writeAll("&#39;"),
            else => try writer.writeByte(c),
        }
    }
}

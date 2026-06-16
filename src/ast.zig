const std = @import("std");

pub const Span = struct {
    start: usize,
    end: usize,
};

pub const TagStyle = enum {
    tilde,
    percent,
    question,
};

pub const ScriptKind = enum {
    block,
    expr,
};

pub const ScriptBlock = struct {
    span: Span,
    style: TagStyle = .tilde,
    kind: ScriptKind = .block,
};

pub const Chunk = union(enum) {
    text: Span,
    script: ScriptBlock,
};

pub const Program = struct {
    source: []const u8,
    chunks: []const Chunk,

    pub fn deinit(self: *Program, allocator: std.mem.Allocator) void {
        allocator.free(self.chunks);
        self.source = "";
        self.chunks = &.{};
    }
};

pub const StatementKind = enum {
    assign,
    call,
    print,
    if_stmt,
    for_loop,
    while_loop,
    foreach_loop,
    grid_loop,
    break_stmt,
    continue_stmt,
    return_stmt,
    include_stmt,
    jump_stmt,
    function_def,
    local_decl,
};

pub const ExpressionKind = enum {
    literal,
    identifier,
    unary,
    binary,
    call,
    property,
    index,
    constructor,
};

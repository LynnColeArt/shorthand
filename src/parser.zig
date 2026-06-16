const std = @import("std");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");

pub const Error = lexer.Error || error{OutOfMemory};

pub const Parser = struct {
    allocator: std.mem.Allocator,
    lexer: lexer.Lexer,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Parser {
        return .{
            .allocator = allocator,
            .lexer = lexer.Lexer.init(source),
        };
    }

    pub fn parse(self: *Parser) Error!ast.Program {
        var count: usize = 0;
        while (try self.lexer.nextChunk()) |_| {
            count += 1;
        }

        self.lexer.reset();
        const chunks = try self.allocator.alloc(ast.Chunk, count);
        var i: usize = 0;
        while (try self.lexer.nextChunk()) |chunk| {
            chunks[i] = chunk;
            i += 1;
        }

        return .{ .source = self.lexer.source, .chunks = chunks };
    }
};

const std = @import("std");
const short = @import("short");

const max_file_bytes: usize = 16 * 1024 * 1024;
const max_response_bytes: usize = 16 * 1024 * 1024;

fn printUsage() void {
    std.debug.print(
        \\{s} - ShortHand compatibility scaffold
        \\
        \\Usage:
        \\  short <command> [args...]
        \\
        \\Commands:
        \\  help      Show this help
        \\  lex       Scan source chunks
        \\  parse     Parse and print chunk summary
        \\  cgi       Show CGI deployment/request snapshot
        \\  run       Execute source as a CGI-style response
        \\
        \\  --strict  Enable strict typing for the selected command
        \\
        \\Preferred source files use the .short extension.
        \\Legacy aliases: .tran, .shh, .shl
        \\
    , .{short.project_name});
}

fn readSource(io: std.Io, allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    return std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(max_file_bytes));
}

fn readRequestBody(io: std.Io, allocator: std.mem.Allocator, environ_map: *const std.process.Environ.Map) ![]u8 {
    const raw_length = environ_map.get("CONTENT_LENGTH") orelse return try allocator.alloc(u8, 0);
    const length = std.fmt.parseInt(usize, raw_length, 10) catch return error.InvalidContentLength;
    if (length == 0) return try allocator.alloc(u8, 0);
    if (length > max_file_bytes) return error.StreamTooLong;

    const body = try allocator.alloc(u8, length);
    var stdin_buffer: [4096]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().reader(io, &stdin_buffer);
    try stdin_reader.interface.readSliceAll(body);
    return body;
}

fn writeErrorResponse(stdout: anytype, allocator: std.mem.Allocator, status_code: u16, body: []const u8) !void {
    var response_state = short.response.ResponseState{
        .status_code = status_code,
        .content_type = "text/plain; charset=utf-8",
    };
    defer response_state.deinit(allocator);
    try response_state.writeHeaders(stdout);
    try stdout.writeAll(body);
    try stdout.flush();
}

fn tagStyleName(style: short.ast.TagStyle) []const u8 {
    return switch (style) {
        .tilde => "tilde",
        .percent => "percent",
        .question => "question",
    };
}

fn scriptKindName(kind: short.ast.ScriptKind) []const u8 {
    return switch (kind) {
        .block => "block",
        .expr => "expr",
    };
}

fn printChunk(chunk: short.ast.Chunk) void {
    switch (chunk) {
        .text => |span| std.debug.print("text[{d}..{d}] len={d}\n", .{
            span.start,
            span.end,
            span.end - span.start,
        }),
        .script => |script| std.debug.print(
            "script(style={s}, kind={s})[{d}..{d}] len={d}\n",
            .{
                tagStyleName(script.style),
                scriptKindName(script.kind),
                script.span.start,
                script.span.end,
                script.span.end - script.span.start,
            },
        ),
    }
}

fn printCgiContext(context: short.cgi.RuntimeContext) void {
    std.debug.print("deployment.mode: {s}\n", .{short.deployment.modeName(context.deployment.mode)});
    std.debug.print("deployment.server_software: {s}\n", .{context.deployment.server_software});
    std.debug.print("deployment.document_root: {s}\n", .{context.deployment.document_root});
    std.debug.print("deployment.script_filename: {s}\n", .{context.deployment.script_filename});
    std.debug.print("deployment.gateway_interface: {s}\n", .{context.deployment.gateway_interface});
    std.debug.print("strict_typing: {any}\n", .{context.strict_typing});
    std.debug.print("request.method: {s}\n", .{context.request.method});
    std.debug.print("request.script_name: {s}\n", .{context.request.script_name});
    std.debug.print("request.path_info: {s}\n", .{context.request.path_info});
    std.debug.print("request.query_string: {s}\n", .{context.request.query_string});
    std.debug.print("request.remote_addr: {s}\n", .{context.request.remote_addr});
    std.debug.print("request.user_agent: {s}\n", .{context.request.user_agent});
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);
    const strict_mode = args.len > 1 and std.mem.eql(u8, args[1], "--strict");
    const command_index: usize = if (strict_mode) 2 else 1;

    if (args.len < command_index + 1 or std.mem.eql(u8, args[command_index], "help") or std.mem.eql(u8, args[command_index], "--help") or std.mem.eql(u8, args[command_index], "-h")) {
        printUsage();
        return;
    }

    const command = args[command_index];
    if (std.mem.eql(u8, command, "lex")) {
        if (args.len < command_index + 2) {
            printUsage();
            return;
        }

        const source = try readSource(init.io, allocator, args[command_index + 1]);
        defer allocator.free(source);

        var lexer = short.lexer.Lexer.init(source);
        while (try lexer.nextChunk()) |chunk| {
            printChunk(chunk);
        }
        return;
    }
    if (std.mem.eql(u8, command, "parse")) {
        if (args.len < command_index + 2) {
            printUsage();
            return;
        }

        const source = try readSource(init.io, allocator, args[command_index + 1]);
        defer allocator.free(source);

        var parser = short.parser.Parser.init(allocator, source);
        var program = try parser.parse();
        defer program.deinit(allocator);

        std.debug.print("chunks: {d}\n", .{program.chunks.len});
        for (program.chunks) |chunk| {
            printChunk(chunk);
        }
        return;
    }
    if (std.mem.eql(u8, command, "cgi")) {
        const context = short.cgi.runtimeContextFromEnvironMap(init.environ_map);
        printCgiContext(context);
        return;
    }
    if (std.mem.eql(u8, command, "run")) {
        const script_path = if (args.len >= command_index + 2) args[command_index + 1] else init.environ_map.get("SCRIPT_FILENAME") orelse "";
        if (script_path.len == 0) {
            printUsage();
            return;
        }

        const source = try readSource(init.io, allocator, script_path);
        defer allocator.free(source);

        var runtime = short.runtime.Runtime.fromCgiEnvironment(init.io, allocator, init.environ_map);
        defer runtime.deinit();
        runtime.context.strict_typing = strict_mode or runtime.context.strict_typing;
        runtime.context.deployment.script_filename = script_path;
        if (runtime.context.request.script_name.len == 0) {
            runtime.context.request.script_name = script_path;
        }

        const request_body = try readRequestBody(init.io, allocator, init.environ_map);
        runtime.context.request.body = request_body;

        const response_buffer = try allocator.alloc(u8, max_response_bytes);
        defer allocator.free(response_buffer);
        var body_writer: std.Io.Writer = .fixed(response_buffer);

        var stdout_buffer: [4096]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
        const stdout = &stdout_writer.interface;

        runtime.runSource(source, &body_writer) catch {
            try writeErrorResponse(stdout, allocator, 500, "Internal Server Error\n");
            return;
        };

        try runtime.writeHeaders(stdout);
        try stdout.writeAll(body_writer.buffered());
        try stdout.flush();
        return;
    }

    std.debug.print("unknown command: {s}\n", .{command});
    printUsage();
}

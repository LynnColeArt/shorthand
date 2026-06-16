const std = @import("std");
const ast = @import("ast.zig");
const cgi = @import("cgi.zig");
const date = @import("date.zig");
const collections = @import("collections.zig");
const db = @import("dbrouter.zig");
const dbspec = @import("dbspec.zig");
const fileobj = @import("fileobj.zig");
const parser = @import("parser.zig");
const regex = @import("regex.zig");
const response = @import("response.zig");
const value = @import("value.zig");

const max_source_bytes: usize = 16 * 1024 * 1024;

fn valueToInt(v: value.Value) i64 {
    return switch (v) {
        .none => 0,
        .boolean => |b| if (b) 1 else 0,
        .integer => |i| i,
        .float => |f| @as(i64, @intFromFloat(f)),
        .string => |s| std.fmt.parseInt(i64, s, 10) catch blk: {
            const parsed = std.fmt.parseFloat(f64, s) catch break :blk 0;
            break :blk @as(i64, @intFromFloat(parsed));
        },
        .cookie => |cookie| std.fmt.parseInt(i64, cookie.value, 10) catch blk: {
            const parsed = std.fmt.parseFloat(f64, cookie.value) catch break :blk 0;
            break :blk @as(i64, @intFromFloat(parsed));
        },
        .object => 0,
    };
}

pub const RuntimeContext = cgi.RuntimeContext;

const Variable = struct {
    name: []u8,
    value: value.Value,
};

const FunctionDef = struct {
    name: []u8,
    params: [][]u8,
    body_source: []u8,
    current_path: []u8,
};

const TokenKind = enum {
    eof,
    eol,
    identifier,
    number,
    string,
    l_paren,
    r_paren,
    comma,
    dot,
    l_bracket,
    r_bracket,
    plus,
    minus,
    star,
    slash,
    amp,
    eq,
    lt,
    gt,
    lte,
    gte,
    neq,
};

const Token = struct {
    kind: TokenKind,
    start: usize,
    end: usize,
};

const Flow = union(enum) {
    normal,
    return_value: value.Value,
    exit,
};

const BlockResult = union(enum) {
    flow: Flow,
    stop: BlockStop,
};

const BlockStop = enum {
    eof,
    if_branch,
    elseif_branch,
    else_branch,
    end_if,
    end_while,
    end_for,
    end_function,
};

pub const Runtime = struct {
    io: std.Io,
    allocator: std.mem.Allocator,
    context: RuntimeContext,
    legacy_mode: bool = true,
    variables: std.ArrayList(Variable) = .empty,
    functions: std.ArrayList(FunctionDef) = .empty,
    objects: std.ArrayList(value.ObjectValue) = .empty,
    random_seeded: bool = false,
    random_prng: std.Random.DefaultPrng = std.Random.DefaultPrng.init(0),

    pub fn init(io: std.Io, allocator: std.mem.Allocator, context: RuntimeContext) Runtime {
        return .{
            .io = io,
            .allocator = allocator,
            .context = context,
        };
    }

    pub fn deinit(self: *Runtime) void {
        self.clearVariables();
        self.clearFunctions();
        self.clearObjects();
        self.variables.deinit(self.allocator);
        self.functions.deinit(self.allocator);
        self.objects.deinit(self.allocator);
        self.context.response.deinit(self.allocator);
    }

    pub fn canMutateHeaders(self: *const Runtime) bool {
        return self.context.deployment.buffer_headers and self.context.response.canMutateHeaders();
    }

    pub fn beginBody(self: *Runtime) void {
        self.context.response.beginBody();
    }

    pub fn setHeader(self: *Runtime, name: []const u8, header_value: []const u8) response.Error!void {
        try self.context.response.setHeader(self.allocator, name, header_value);
    }

    pub fn setCookie(self: *Runtime, cookie: response.CookieSpec) response.Error!void {
        try self.context.response.setCookie(self.allocator, cookie);
    }

    pub fn redirect(self: *Runtime, location: []const u8) response.Error!void {
        try self.context.response.redirect(self.allocator, location);
    }

    pub fn writeHeaders(self: *Runtime, writer: anytype) anyerror!void {
        try self.context.response.writeHeaders(writer);
    }

    pub fn fromCgiEnvironment(io: std.Io, allocator: std.mem.Allocator, environ_map: *const std.process.Environ.Map) Runtime {
        return .{
            .io = io,
            .allocator = allocator,
            .context = cgi.runtimeContextFromEnvironMap(environ_map),
        };
    }

    pub fn runSource(self: *Runtime, source: []const u8, writer: anytype) anyerror!void {
        try self.runSourceAtPath(source, writer, self.currentScriptPath());
    }

    pub fn runProgram(self: *Runtime, program: ast.Program, writer: anytype) anyerror!void {
        try self.runProgramAtPath(program, writer, self.currentScriptPath());
    }

    fn runSourceAtPath(self: *Runtime, source: []const u8, writer: anytype, current_path: []const u8) anyerror!void {
        var parsed = parser.Parser.init(self.allocator, source);
        var program = try parsed.parse();
        defer program.deinit(self.allocator);
        try self.runProgramAtPath(program, writer, current_path);
    }

    fn runProgramAtPath(self: *Runtime, program: ast.Program, writer: anytype, current_path: []const u8) anyerror!void {
        for (program.chunks) |chunk| {
            switch (chunk) {
                .text => |span| {
                    const text = program.source[span.start..span.end];
                    if (text.len != 0) {
                        try writer.writeAll(text);
                        self.context.response.noteWrite(text.len);
                    }
                },
                .script => |script| {
                    const body = program.source[script.span.start..script.span.end];
                    var runner = try Runner.init(self, body, current_path);
                    defer runner.deinit();

                    const flow = switch (script.kind) {
                        .expr => try runner.runExpressionChunk(writer),
                        .block => try runner.runBlockChunk(writer),
                    };

                    switch (flow) {
                        .normal => {},
                        .return_value => return,
                        .exit => return,
                    }
                },
            }
        }
    }

    fn currentScriptPath(self: *Runtime) []const u8 {
        if (self.context.deployment.script_filename.len != 0) return self.context.deployment.script_filename;
        if (self.context.request.script_name.len != 0) return self.context.request.script_name;
        return "";
    }

    fn clearVariables(self: *Runtime) void {
        for (self.variables.items) |binding| {
            self.allocator.free(binding.name);
            self.freeValue(binding.value);
        }
        self.variables.clearRetainingCapacity();
    }

    fn clearFunctions(self: *Runtime) void {
        for (self.functions.items) |def| {
            self.allocator.free(def.name);
            for (def.params) |param| self.allocator.free(param);
            self.allocator.free(def.params);
            self.allocator.free(def.body_source);
            self.allocator.free(def.current_path);
        }
        self.functions.clearRetainingCapacity();
    }

    fn clearObjects(self: *Runtime) void {
        for (self.objects.items) |object| {
            switch (object.kind) {
                .connection, .recordset, .ddl => db.deinitObject(self.allocator, object),
                .array, .map => {},
                .file => fileobj.deinitObject(self.allocator, self.io, object),
            }
        }
        self.objects.clearRetainingCapacity();
    }

    fn variableIndex(self: *Runtime, name: []const u8) ?usize {
        for (self.variables.items, 0..) |binding, index| {
            if (std.ascii.eqlIgnoreCase(binding.name, name)) return index;
        }
        return null;
    }

    fn getVariable(self: *Runtime, name: []const u8) ?value.Value {
        if (self.variableIndex(name)) |index| return self.variables.items[index].value;
        return null;
    }

    fn setVariable(self: *Runtime, name: []const u8, new_value: value.Value) !void {
        if (self.variableIndex(name)) |index| {
            const binding = &self.variables.items[index];
            self.freeValue(binding.value);
            binding.value = try self.cloneValue(new_value);
            return;
        }

        try self.variables.append(self.allocator, .{
            .name = try canonicalName(self.allocator, name),
            .value = try self.cloneValue(new_value),
        });
    }

    fn cloneValue(self: *Runtime, v: value.Value) !value.Value {
        return try self.cloneValueToAllocator(self.allocator, v);
    }

    fn cloneValueToAllocator(self: *Runtime, allocator: std.mem.Allocator, v: value.Value) anyerror!value.Value {
        return switch (v) {
            .none => .{ .none = {} },
            .boolean => |b| .{ .boolean = b },
            .integer => |i| .{ .integer = i },
            .float => |f| .{ .float = f },
            .string => |s| .{ .string = try allocator.dupe(u8, s) },
            .cookie => |cookie| .{ .cookie = try self.cloneCookieSpec(allocator, cookie) },
            .object => |object| switch (object.kind) {
                .connection, .recordset, .ddl, .file => .{ .object = object },
                .array => .{ .object = try self.cloneArrayObject(allocator, @as(*collections.ArrayState, @ptrCast(@alignCast(object.ptr)))) },
                .map => .{ .object = try self.cloneMapObject(allocator, @as(*collections.MapState, @ptrCast(@alignCast(object.ptr)))) },
            },
        };
    }

    fn freeValue(self: *Runtime, v: value.Value) void {
        switch (v) {
            .string => |s| self.allocator.free(s),
            .cookie => |cookie| {
                self.allocator.free(cookie.name);
                self.allocator.free(cookie.value);
                if (cookie.path) |path| self.allocator.free(path);
                if (cookie.domain) |domain| self.allocator.free(domain);
                if (cookie.expires) |expires| self.allocator.free(expires);
            },
            .object => |object| switch (object.kind) {
                .array => self.freeArrayState(@as(*collections.ArrayState, @ptrCast(@alignCast(object.ptr)))),
                .map => self.freeMapState(@as(*collections.MapState, @ptrCast(@alignCast(object.ptr)))),
                else => {},
            },
            else => {},
        }
    }

    fn registerObject(self: *Runtime, object: value.ObjectValue) !value.Value {
        try self.objects.append(self.allocator, object);
        return .{ .object = object };
    }

    fn cloneCookieSpec(self: *Runtime, allocator: std.mem.Allocator, cookie: response.CookieSpec) !response.CookieSpec {
        _ = self;
        return .{
            .name = try allocator.dupe(u8, cookie.name),
            .value = try allocator.dupe(u8, cookie.value),
            .path = if (cookie.path) |path| try allocator.dupe(u8, path) else null,
            .domain = if (cookie.domain) |domain| try allocator.dupe(u8, domain) else null,
            .expires = if (cookie.expires) |expires| try allocator.dupe(u8, expires) else null,
            .secure = cookie.secure,
        };
    }

    fn freeArrayState(self: *Runtime, state: *collections.ArrayState) void {
        for (state.items.items) |item| {
            self.freeValue(item);
        }
        state.items.deinit(state.allocator);
        state.allocator.destroy(state);
    }

    fn freeMapState(self: *Runtime, state: *collections.MapState) void {
        for (state.entries.items) |entry| {
            self.freeValue(entry.value);
            state.allocator.free(entry.key);
        }
        state.entries.deinit(state.allocator);
        state.allocator.destroy(state);
    }

    fn clearArrayState(self: *Runtime, state: *collections.ArrayState) void {
        for (state.items.items) |item| {
            self.freeValue(item);
        }
        state.items.deinit(state.allocator);
        state.items = .empty;
        state.lower_bound = 1;
        state.allocated = false;
    }

    fn clearMapState(self: *Runtime, state: *collections.MapState) void {
        for (state.entries.items) |entry| {
            self.freeValue(entry.value);
            state.allocator.free(entry.key);
        }
        state.entries.deinit(state.allocator);
        state.entries = .empty;
        state.allocated = false;
    }

    fn destroyArrayStateOnly(state: *collections.ArrayState) void {
        state.items.deinit(state.allocator);
        state.allocator.destroy(state);
    }

    fn destroyMapStateOnly(state: *collections.MapState) void {
        for (state.entries.items) |entry| {
            state.allocator.free(entry.key);
        }
        state.entries.deinit(state.allocator);
        state.allocator.destroy(state);
    }

    fn cloneArrayObject(self: *Runtime, allocator: std.mem.Allocator, state: *collections.ArrayState) anyerror!value.ObjectValue {
        const cloned_state = try allocator.create(collections.ArrayState);
        cloned_state.* = .{
            .allocator = allocator,
            .allocated = state.allocated,
            .lower_bound = state.lower_bound,
            .items = .empty,
        };
        errdefer self.freeArrayState(cloned_state);

        for (state.items.items) |item| {
            const cloned_item = try self.cloneValueToAllocator(allocator, item);
            cloned_state.items.append(allocator, cloned_item) catch |err| {
                self.freeValue(cloned_item);
                return err;
            };
        }

        return .{ .kind = .array, .ptr = cloned_state };
    }

    fn cloneMapObject(self: *Runtime, allocator: std.mem.Allocator, state: *collections.MapState) anyerror!value.ObjectValue {
        const cloned_state = try allocator.create(collections.MapState);
        cloned_state.* = .{
            .allocator = allocator,
            .allocated = state.allocated,
            .entries = .empty,
        };
        errdefer self.freeMapState(cloned_state);

        for (state.entries.items) |entry| {
            const key_copy = try allocator.dupe(u8, entry.key);
            const cloned_value = try self.cloneValueToAllocator(allocator, entry.value);
            cloned_state.entries.append(allocator, .{
                .key = key_copy,
                .value = cloned_value,
            }) catch |err| {
                self.freeValue(cloned_value);
                allocator.free(key_copy);
                return err;
            };
        }

        return .{ .kind = .map, .ptr = cloned_state };
    }

    fn currentUnixSeconds() i64 {
        var ts: std.posix.timespec = undefined;
        switch (std.posix.errno(std.posix.system.clock_gettime(.REALTIME, &ts))) {
            .SUCCESS => return @as(i64, @intCast(ts.sec)),
            else => return 0,
        }
    }

    fn formatHttpDate(self: *Runtime, allocator: std.mem.Allocator, epoch_seconds: i64) ![]u8 {
        _ = self;
        const secs = if (epoch_seconds < 0) @as(u64, 0) else @as(u64, @intCast(epoch_seconds));
        const epoch_seconds_value = std.time.epoch.EpochSeconds{ .secs = secs };
        const epoch_day = epoch_seconds_value.getEpochDay();
        const year_day = epoch_day.calculateYearDay();
        const month_day = year_day.calculateMonthDay();
        const day_seconds = epoch_seconds_value.getDaySeconds();
        const weekday_index = @as(usize, @intCast((epoch_day.day + 4) % 7));
        const weekday_names = [_][]const u8{ "Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed" };
        const month_names = [_][]const u8{ "", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };
        return try std.fmt.allocPrint(allocator, "{s}, {d:0>2} {s} {d:0>4} {d:0>2}:{d:0>2}:{d:0>2} GMT", .{
            weekday_names[weekday_index],
            @as(u8, @intCast(month_day.day_index + 1)),
            month_names[month_day.month.numeric()],
            year_day.year,
            day_seconds.getHoursIntoDay(),
            day_seconds.getMinutesIntoHour(),
            day_seconds.getSecondsIntoMinute(),
        });
    }

    fn cookieExpiryText(self: *Runtime, allocator: std.mem.Allocator, v: value.Value) !?[]u8 {
        return switch (v) {
            .none => null,
            .string => |s| try allocator.dupe(u8, s),
            .boolean => |b| blk: {
                const seconds: i64 = if (b) 1 else 0;
                break :blk try self.formatHttpDate(allocator, seconds);
            },
            .integer => |i| try self.formatHttpDate(allocator, i),
            .float => |f| try self.formatHttpDate(allocator, @as(i64, @intFromFloat(f))),
            .cookie => |cookie| if (cookie.expires) |expires| try allocator.dupe(u8, expires) else null,
            .object => null,
        };
    }

    fn randomGenerator(self: *Runtime) *std.Random.DefaultPrng {
        if (!self.random_seeded) {
            const seed = @as(u64, @intCast(@abs(currentUnixSeconds()))) ^
                @as(u64, @intCast(@intFromPtr(self)));
            self.random_prng = std.Random.DefaultPrng.init(seed);
            self.random_seeded = true;
        }
        return &self.random_prng;
    }

    fn randomIntRange(self: *Runtime, min_value: i64, max_value: i64) i64 {
        const low = @min(min_value, max_value);
        const high = @max(min_value, max_value);
        if (low == std.math.minInt(i64) and high == std.math.maxInt(i64)) {
            return @bitCast(self.randomGenerator().random().int(u64));
        }

        const span = @as(u64, @intCast(@as(i128, high) - @as(i128, low) + 1));
        const sample = self.randomGenerator().random().int(u64) % span;
        return @as(i64, @intCast(@as(i128, low) + @as(i128, sample)));
    }

    fn arrayStateFromValue(v: value.Value) ?*collections.ArrayState {
        return switch (v) {
            .object => |object| if (object.kind == .array) @as(*collections.ArrayState, @ptrCast(@alignCast(object.ptr))) else null,
            else => null,
        };
    }

    fn mapStateFromValue(v: value.Value) ?*collections.MapState {
        return switch (v) {
            .object => |object| if (object.kind == .map) @as(*collections.MapState, @ptrCast(@alignCast(object.ptr))) else null,
            else => null,
        };
    }

    fn createArrayValue(self: *Runtime, allocator: std.mem.Allocator, lower_bound: i64, items: []const value.Value) !value.Value {
        const state = try allocator.create(collections.ArrayState);
        state.* = .{
            .allocator = allocator,
            .allocated = true,
            .lower_bound = lower_bound,
            .items = .empty,
        };
        errdefer self.freeArrayState(state);

        for (items) |item| {
            const cloned_item = try self.cloneValueToAllocator(allocator, item);
            state.items.append(allocator, cloned_item) catch |err| {
                self.freeValue(cloned_item);
                return err;
            };
        }

        return .{ .object = .{ .kind = .array, .ptr = state } };
    }

    const MapPair = struct {
        key: []const u8,
        value: value.Value,
    };

    fn createMapValue(self: *Runtime, allocator: std.mem.Allocator, entries: []const MapPair) !value.Value {
        const state = try allocator.create(collections.MapState);
        state.* = .{
            .allocator = allocator,
            .allocated = true,
            .entries = .empty,
        };
        errdefer self.freeMapState(state);

        for (entries) |entry| {
            const key_copy = try allocator.dupe(u8, entry.key);
            const cloned_value = try self.cloneValueToAllocator(allocator, entry.value);
            state.entries.append(allocator, .{
                .key = key_copy,
                .value = cloned_value,
            }) catch |err| {
                self.freeValue(cloned_value);
                allocator.free(key_copy);
                return err;
            };
        }

        return .{ .object = .{ .kind = .map, .ptr = state } };
    }

    fn isContainerValue(v: value.Value) bool {
        return switch (v) {
            .object => |object| object.kind == .array or object.kind == .map,
            else => false,
        };
    }

    fn ensureMapEntryIndex(_: *Runtime, state: *collections.MapState, key: []const u8) !usize {
        for (state.entries.items, 0..) |entry, index| {
            if (std.mem.eql(u8, entry.key, key)) return index;
        }

        try state.entries.append(state.allocator, .{
            .key = try state.allocator.dupe(u8, key),
            .value = .{ .none = {} },
        });
        return state.entries.items.len - 1;
    }

    fn moveArrayState(self: *Runtime, from_state: *collections.ArrayState, to_state: *collections.ArrayState) void {
        if (from_state == to_state) return;
        self.clearArrayState(to_state);
        if (!from_state.allocated) return;
        to_state.allocator = from_state.allocator;
        to_state.allocated = true;
        to_state.lower_bound = from_state.lower_bound;
        to_state.items = from_state.items;
        from_state.items = .empty;
        from_state.lower_bound = 1;
        from_state.allocated = false;
    }

    fn moveMapState(self: *Runtime, from_state: *collections.MapState, to_state: *collections.MapState) void {
        if (from_state == to_state) return;
        self.clearMapState(to_state);
        if (!from_state.allocated) return;
        to_state.allocator = from_state.allocator;
        to_state.allocated = true;
        to_state.entries = from_state.entries;
        from_state.entries = .empty;
        from_state.allocated = false;
    }

    fn functionIndex(self: *Runtime, name: []const u8) ?usize {
        var i: usize = self.functions.items.len;
        while (i > 0) {
            i -= 1;
            if (std.ascii.eqlIgnoreCase(self.functions.items[i].name, name)) return i;
        }
        return null;
    }

    fn getFunction(self: *Runtime, name: []const u8) ?*FunctionDef {
        if (self.functionIndex(name)) |index| return &self.functions.items[index];
        return null;
    }

    fn registerFunction(
        self: *Runtime,
        name: []const u8,
        params: [][]u8,
        body_source: []const u8,
        current_path: []const u8,
    ) !void {
        try self.functions.append(self.allocator, .{
            .name = try canonicalName(self.allocator, name),
            .params = params,
            .body_source = try self.allocator.dupe(u8, body_source),
            .current_path = try self.allocator.dupe(u8, current_path),
        });
    }
};

const Runner = struct {
    runtime: *Runtime,
    source: []const u8,
    current_path: []const u8,
    tokens: []Token,
    pos: usize = 0,
    temp_arena: std.heap.ArenaAllocator,

    pub fn init(runtime: *Runtime, source: []const u8, current_path: []const u8) !Runner {
        var temp_arena = std.heap.ArenaAllocator.init(runtime.allocator);
        errdefer temp_arena.deinit();

        var token_list: std.ArrayList(Token) = .empty;
        errdefer token_list.deinit(runtime.allocator);
        try tokenize(runtime.allocator, source, &token_list);

        return .{
            .runtime = runtime,
            .source = source,
            .current_path = current_path,
            .tokens = try token_list.toOwnedSlice(runtime.allocator),
            .temp_arena = temp_arena,
        };
    }

    pub fn deinit(self: *Runner) void {
        self.runtime.allocator.free(self.tokens);
        self.temp_arena.deinit();
    }

    fn tmpAllocator(self: *Runner) std.mem.Allocator {
        return self.temp_arena.allocator();
    }

    fn resetTemps(self: *Runner) void {
        _ = self.temp_arena.reset(.retain_capacity);
    }

    fn atEnd(self: *const Runner) bool {
        return self.pos >= self.tokens.len or self.tokens[self.pos].kind == .eof;
    }

    fn current(self: *const Runner) Token {
        return self.tokens[self.pos];
    }

    fn peek(self: *const Runner, offset: usize) ?Token {
        const index = self.pos + offset;
        if (index >= self.tokens.len) return null;
        return self.tokens[index];
    }

    fn text(self: *const Runner, token: Token) []const u8 {
        return self.source[token.start..token.end];
    }

    fn matchIdentifier(self: *const Runner, name: []const u8) bool {
        const token = self.peek(0) orelse return false;
        return token.kind == .identifier and std.ascii.eqlIgnoreCase(self.text(token), name);
    }

    fn matchEndPair(self: *const Runner, second: []const u8) bool {
        const first = self.peek(0) orelse return false;
        const next = self.peek(1) orelse return false;
        return first.kind == .identifier and next.kind == .identifier and
            std.ascii.eqlIgnoreCase(self.text(first), "end") and std.ascii.eqlIgnoreCase(self.text(next), second);
    }

    fn consumeIdentifier(self: *Runner) ![]const u8 {
        const token = self.peek(0) orelse return error.InvalidExpression;
        if (token.kind != .identifier) return error.InvalidExpression;
        self.pos += 1;
        return self.text(token);
    }

    fn consumeKeyword(self: *Runner, name: []const u8) !void {
        if (!self.matchIdentifier(name)) return error.InvalidExpression;
        self.pos += 1;
    }

    fn skipEols(self: *Runner) void {
        while (self.peek(0)) |token| {
            if (token.kind != .eol) break;
            self.pos += 1;
        }
    }

    fn maybeConsumeThen(self: *Runner) void {
        if (self.matchIdentifier("then") or self.matchIdentifier("do")) {
            self.pos += 1;
        }
    }

    fn consumeEndIf(self: *Runner) !void {
        if (!self.matchEndPair("if")) return error.InvalidExpression;
        self.pos += 2;
    }

    fn consumeEndWhile(self: *Runner) !void {
        if (!self.matchEndPair("while") and !self.matchIdentifier("wend")) return error.InvalidExpression;
        if (self.matchIdentifier("wend")) {
            self.pos += 1;
            return;
        }
        self.pos += 2;
    }

    fn consumeEndFunction(self: *Runner) !void {
        if (!self.matchEndPair("function")) return error.InvalidExpression;
        self.pos += 2;
    }

    fn consumeEndFor(self: *Runner) !void {
        if (!self.matchEndPair("for")) return error.InvalidExpression;
        self.pos += 2;
    }

    fn isIfBranchStop(self: *const Runner) ?BlockStop {
        if (self.matchIdentifier("elseif")) return .elseif_branch;
        if (self.matchIdentifier("else")) return .else_branch;
        if (self.matchEndPair("if")) return .end_if;
        return null;
    }

    fn isEndWhileStop(self: *const Runner) ?BlockStop {
        if (self.matchEndPair("while") or self.matchIdentifier("wend")) return .end_while;
        return null;
    }

    fn isEndFunctionStop(self: *const Runner) ?BlockStop {
        if (self.matchEndPair("function")) return .end_function;
        return null;
    }

    fn isEndForStop(self: *const Runner) ?BlockStop {
        if (self.matchEndPair("for")) return .end_for;
        return null;
    }

    fn emitText(self: *Runner, writer: anytype, chunk_text: []const u8) anyerror!void {
        if (chunk_text.len == 0) return;
        try writer.writeAll(chunk_text);
        self.runtime.context.response.noteWrite(chunk_text.len);
    }

    fn emitValue(self: *Runner, writer: anytype, v: value.Value) anyerror!void {
        const rendered = try self.valueText(v);
        try self.emitText(writer, rendered);
    }

    fn appendEscapedString(self: *Runner, out: *std.ArrayList(u8), input: []const u8) anyerror!void {
        const allocator = self.tmpAllocator();
        try out.append(allocator, '"');
        for (input) |ch| {
            switch (ch) {
                '\\' => try out.appendSlice(allocator, "\\\\"),
                '"' => try out.appendSlice(allocator, "\\\""),
                '\n' => try out.appendSlice(allocator, "\\n"),
                '\r' => try out.appendSlice(allocator, "\\r"),
                '\t' => try out.appendSlice(allocator, "\\t"),
                else => try out.append(allocator, ch),
            }
        }
        try out.append(allocator, '"');
    }

    fn appendValueText(self: *Runner, out: *std.ArrayList(u8), v: value.Value) anyerror!void {
        const allocator = self.tmpAllocator();
        switch (v) {
            .none => try out.appendSlice(allocator, "null"),
            .boolean => |b| try out.appendSlice(allocator, if (b) "true" else "false"),
            .integer => |i| {
                var buf: [64]u8 = undefined;
                const printed = try std.fmt.bufPrint(&buf, "{d}", .{i});
                try out.appendSlice(allocator, printed);
            },
            .float => |f| {
                var buf: [128]u8 = undefined;
                const printed = try std.fmt.bufPrint(&buf, "{d}", .{f});
                try out.appendSlice(allocator, printed);
            },
            .string => |s| try self.appendEscapedString(out, s),
            .cookie => |cookie| try self.appendEscapedString(out, cookie.value),
            .object => |object| switch (object.kind) {
                .array => {
                    const state = @as(*collections.ArrayState, @ptrCast(@alignCast(object.ptr)));
                    if (!state.allocated) {
                        try out.appendSlice(allocator, "null");
                        return;
                    }
                    try out.appendSlice(allocator, "[");
                    for (state.items.items, 0..) |item, index| {
                        if (index != 0) try out.appendSlice(allocator, ", ");
                        try self.appendValueText(out, item);
                    }
                    try out.appendSlice(allocator, "]");
                },
                .map => {
                    const state = @as(*collections.MapState, @ptrCast(@alignCast(object.ptr)));
                    if (!state.allocated) {
                        try out.appendSlice(allocator, "null");
                        return;
                    }
                    try out.appendSlice(allocator, "{");
                    var order = try allocator.alloc(usize, state.entries.items.len);
                    defer allocator.free(order);
                    for (order, 0..) |*slot, index| slot.* = index;
                    var i: usize = 0;
                    while (i < order.len) : (i += 1) {
                        var best = i;
                        var j = i + 1;
                        while (j < order.len) : (j += 1) {
                            if (std.mem.order(u8, state.entries.items[order[j]].key, state.entries.items[order[best]].key) == .lt) {
                                best = j;
                            }
                        }
                        if (best != i) {
                            const tmp = order[i];
                            order[i] = order[best];
                            order[best] = tmp;
                        }
                    }
                    for (order, 0..) |entry_index, index| {
                        if (index != 0) try out.appendSlice(allocator, ", ");
                        try self.appendEscapedString(out, state.entries.items[entry_index].key);
                        try out.appendSlice(allocator, ": ");
                        try self.appendValueText(out, state.entries.items[entry_index].value);
                    }
                    try out.appendSlice(allocator, "}");
                },
                else => try out.appendSlice(allocator, ""),
            },
        }
    }

    fn valueText(self: *Runner, v: value.Value) anyerror![]const u8 {
        return switch (v) {
            .none => "",
            .boolean => |b| if (b) "true" else "false",
            .integer => |i| try self.formatValue("{d}", .{i}),
            .float => |f| try self.formatValue("{d}", .{f}),
            .string => |s| s,
            .cookie => |cookie| cookie.value,
            .object => |object| switch (object.kind) {
                .array, .map => blk: {
                    const allocator = self.tmpAllocator();
                    var out: std.ArrayList(u8) = .empty;
                    errdefer out.deinit(allocator);
                    try self.appendValueText(&out, v);
                    break :blk try out.toOwnedSlice(allocator);
                },
                else => "",
            },
        };
    }

    fn substringValue(self: *Runner, input: []const u8, start_value: i64, length_value: ?i64) ![]u8 {
        const start_index: usize = if (start_value <= 1) 0 else @as(usize, @intCast(start_value - 1));
        if (start_index >= input.len) return self.tmpAllocator().dupe(u8, "");
        const max_len = input.len - start_index;
        const slice_len: usize = if (length_value) |length| blk: {
            if (length <= 0) break :blk 0;
            break :blk @min(max_len, @as(usize, @intCast(length)));
        } else max_len;
        return self.tmpAllocator().dupe(u8, input[start_index .. start_index + slice_len]);
    }

    fn replaceValue(self: *Runner, source: []const u8, pattern: []const u8, replacement: []const u8) ![]u8 {
        const allocator = self.tmpAllocator();
        if (pattern.len == 0) return allocator.dupe(u8, source);

        var out: std.ArrayList(u8) = .empty;
        errdefer out.deinit(allocator);

        var last_emit: usize = 0;
        while (std.mem.indexOf(u8, source[last_emit..], pattern)) |offset| {
            const match_index = last_emit + offset;
            try out.appendSlice(allocator, source[last_emit..match_index]);
            try out.appendSlice(allocator, replacement);
            last_emit = match_index + pattern.len;
        }

        if (last_emit < source.len) {
            try out.appendSlice(allocator, source[last_emit..]);
        }

        return try out.toOwnedSlice(allocator);
    }

    fn translateValue(self: *Runner, source: []const u8, from: []const u8, to: []const u8) ![]u8 {
        const allocator = self.tmpAllocator();
        if (from.len == 0 or to.len == 0) return allocator.dupe(u8, source);

        const from_byte = from[0];
        const to_byte = to[0];

        var out: std.ArrayList(u8) = .empty;
        errdefer out.deinit(allocator);

        for (source) |ch| {
            try out.append(allocator, if (ch == from_byte) to_byte else ch);
        }

        return try out.toOwnedSlice(allocator);
    }

    fn lowerValue(self: *Runner, input: []const u8) ![]u8 {
        const allocator = self.tmpAllocator();
        var out: std.ArrayList(u8) = .empty;
        errdefer out.deinit(allocator);

        for (input) |ch| {
            try out.append(allocator, std.ascii.toLower(ch));
        }

        return try out.toOwnedSlice(allocator);
    }

    fn upperValue(self: *Runner, input: []const u8) ![]u8 {
        const allocator = self.tmpAllocator();
        var out: std.ArrayList(u8) = .empty;
        errdefer out.deinit(allocator);

        for (input) |ch| {
            try out.append(allocator, std.ascii.toUpper(ch));
        }

        return try out.toOwnedSlice(allocator);
    }

    fn strposValue(self: *Runner, source: []const u8, pattern: []const u8) i64 {
        _ = self;
        if (pattern.len == 0) return 0;
        if (std.mem.indexOf(u8, source, pattern)) |index| {
            return @intCast(index);
        }
        return -1;
    }

    fn newCookieValue(self: *Runner, args: []value.Value, execute: bool) anyerror!value.Value {
        if (!execute) return .{ .none = {} };
        if (args.len == 0) return .{ .none = {} };

        const allocator = self.tmpAllocator();
        const name = try self.valueText(args[0]);
        const value_text = if (args.len >= 2) try self.valueText(args[1]) else "";
        const expires = if (args.len >= 3) try self.runtime.cookieExpiryText(allocator, args[2]) else null;
        const path = if (args.len >= 4) try allocator.dupe(u8, try self.valueText(args[3])) else null;
        const domain = if (args.len >= 5) try allocator.dupe(u8, try self.valueText(args[4])) else null;
        const secure = if (args.len >= 6) try self.boolValue(args[5]) else false;

        const spec = response.CookieSpec{
            .name = try allocator.dupe(u8, name),
            .value = try allocator.dupe(u8, value_text),
            .path = path,
            .domain = domain,
            .expires = expires,
            .secure = secure,
        };
        return .{ .cookie = spec };
    }

    fn newFileValue(self: *Runner, args: []value.Value, execute: bool) anyerror!value.Value {
        if (!execute) return .{ .none = {} };
        if (args.len == 0) return .{ .none = {} };

        const path = try self.valueText(args[0]);
        const mode = if (args.len >= 2) try self.valueText(args[1]) else "r";
        const state = try fileobj.createState(self.runtime.allocator, self.runtime.io, path, mode);
        return try self.runtime.registerObject(fileobj.object(state));
    }

    fn newConnectionValue(self: *Runner, args: []value.Value, execute: bool) anyerror!value.Value {
        if (!execute) return .{ .none = {} };
        const driver = if (args.len >= 1) try self.valueText(args[0]) else "MySQL";
        const connection_string = if (args.len >= 2) try self.valueText(args[1]) else "";
        return try self.runtime.registerObject(try db.createConnection(self.runtime.allocator, driver, connection_string));
    }

    fn newRecordsetValue(self: *Runner, args: []value.Value, execute: bool) anyerror!value.Value {
        if (!execute) return .{ .none = {} };
        if (args.len < 2) return .{ .none = {} };
        const connection = db.connectionFromValue(args[0]) orelse return .{ .none = {} };
        const sql = try self.valueText(args[1]);
        return try self.runtime.registerObject(try db.createRecordset(self.runtime.allocator, connection, sql));
    }

    fn newDdlValue(self: *Runner, args: []value.Value, execute: bool) anyerror!value.Value {
        if (!execute) return .{ .none = {} };
        if (args.len < 2) return .{ .none = {} };
        const connection = db.connectionFromValue(args[0]) orelse return .{ .none = {} };
        const sql = try self.valueText(args[1]);
        return try self.runtime.registerObject(try db.createDdl(self.runtime.allocator, connection, sql));
    }

    fn formatValue(self: *Runner, comptime fmt: []const u8, args: anytype) ![]const u8 {
        var buf: [512]u8 = undefined;
        const printed = try std.fmt.bufPrint(&buf, fmt, args);
        return self.tmpAllocator().dupe(u8, printed);
    }

    fn toBool(v: value.Value) bool {
        return value.isTruthy(v);
    }

    fn strictMode(self: *const Runner) bool {
        return self.runtime.context.strict_typing;
    }

    fn boolValue(self: *Runner, v: value.Value) !bool {
        if (!self.strictMode()) return toBool(v);
        return switch (v) {
            .none => false,
            .boolean => |b| b,
            else => error.StrictTypeMismatch,
        };
    }

    fn toInt(v: value.Value) i64 {
        return switch (v) {
            .none => 0,
            .boolean => |b| if (b) 1 else 0,
            .integer => |i| i,
            .float => |f| @as(i64, @intFromFloat(f)),
            .string => |s| std.fmt.parseInt(i64, s, 10) catch blk: {
                const parsed = std.fmt.parseFloat(f64, s) catch break :blk 0;
                break :blk @as(i64, @intFromFloat(parsed));
            },
            .cookie => |cookie| std.fmt.parseInt(i64, cookie.value, 10) catch blk: {
                const parsed = std.fmt.parseFloat(f64, cookie.value) catch break :blk 0;
                break :blk @as(i64, @intFromFloat(parsed));
            },
            .object => 0,
        };
    }

    fn toFloat(v: value.Value) f64 {
        return switch (v) {
            .none => 0,
            .boolean => |b| if (b) 1 else 0,
            .integer => |i| @as(f64, @floatFromInt(i)),
            .float => |f| f,
            .string => |s| std.fmt.parseFloat(f64, s) catch 0,
            .cookie => |cookie| std.fmt.parseFloat(f64, cookie.value) catch 0,
            .object => 0,
        };
    }

    fn strictNumericValue(self: *Runner, v: value.Value) !i64 {
        if (!self.strictMode()) return toInt(v);
        return switch (v) {
            .none => 0,
            .integer => |i| i,
            .float => |f| @as(i64, @intFromFloat(f)),
            else => error.StrictTypeMismatch,
        };
    }

    fn strictFloatValue(self: *Runner, v: value.Value) !f64 {
        if (!self.strictMode()) return toFloat(v);
        return switch (v) {
            .none => 0,
            .integer => |i| @as(f64, @floatFromInt(i)),
            .float => |f| f,
            else => error.StrictTypeMismatch,
        };
    }

    fn strictStringValue(self: *Runner, v: value.Value) ![]const u8 {
        if (!self.strictMode()) return try self.valueText(v);
        return switch (v) {
            .none => "",
            .string => |s| s,
            else => error.StrictTypeMismatch,
        };
    }

    fn arrayIndex(self: *Runner, state: *collections.ArrayState, index_value: value.Value) !usize {
        if (!state.allocated) return error.InvalidExpression;
        const index = if (self.strictMode()) try self.strictNumericValue(index_value) else valueToInt(index_value);
        if (index < state.lower_bound) return error.InvalidExpression;
        const offset = index - state.lower_bound;
        return @as(usize, @intCast(offset));
    }

    fn mapKey(self: *Runner, key_value: value.Value) ![]const u8 {
        if (self.strictMode()) return try self.strictStringValue(key_value);
        return try self.valueText(key_value);
    }

    fn indexValue(self: *Runner, base: value.Value, index_value: value.Value) anyerror!value.Value {
        return switch (base) {
            .object => |object| switch (object.kind) {
                .array => {
                    const state = @as(*collections.ArrayState, @ptrCast(@alignCast(object.ptr)));
                    if (!state.allocated) return .{ .none = {} };
                    const index = try self.arrayIndex(state, index_value);
                    if (index >= state.items.items.len) return .{ .none = {} };
                    return state.items.items[index];
                },
                .map => {
                    const state = @as(*collections.MapState, @ptrCast(@alignCast(object.ptr)));
                    if (!state.allocated) return .{ .none = {} };
                    const key = try self.mapKey(index_value);
                    for (state.entries.items) |entry| {
                        if (std.mem.eql(u8, entry.key, key)) return entry.value;
                    }
                    return .{ .none = {} };
                },
                else => .{ .none = {} },
            },
            else => .{ .none = {} },
        };
    }

    fn makeIndexedContainer(self: *Runner, allocator: std.mem.Allocator, index_value: value.Value) !value.Value {
        return switch (index_value) {
            .integer, .float, .boolean, .none => try self.runtime.createArrayValue(allocator, 1, &[_]value.Value{}),
            else => try self.runtime.createMapValue(allocator, &[_]Runtime.MapPair{}),
        };
    }

    fn setIndexedValue(self: *Runner, slot: *value.Value, allocator: std.mem.Allocator, indices: []value.Value, new_value: value.Value) !void {
        if (indices.len == 0) {
            self.runtime.freeValue(slot.*);
            slot.* = try self.runtime.cloneValueToAllocator(allocator, new_value);
            return;
        }

        if (slot.* == .none) {
            slot.* = try self.makeIndexedContainer(allocator, indices[0]);
        } else if (!Runtime.isContainerValue(slot.*)) {
            self.runtime.freeValue(slot.*);
            slot.* = try self.makeIndexedContainer(allocator, indices[0]);
        }

        switch (slot.*) {
            .object => |object| switch (object.kind) {
                .array => {
                    const state = @as(*collections.ArrayState, @ptrCast(@alignCast(object.ptr)));
                    if (!state.allocated) {
                        state.allocated = true;
                        state.lower_bound = 1;
                    }
                    const index = try self.arrayIndex(state, indices[0]);
                    while (state.items.items.len <= index) {
                        try state.items.append(state.allocator, .{ .none = {} });
                    }
                    if (indices.len == 1) {
                        self.runtime.freeValue(state.items.items[index]);
                        state.items.items[index] = try self.runtime.cloneValueToAllocator(state.allocator, new_value);
                        return;
                    }
                    if (!Runtime.isContainerValue(state.items.items[index])) {
                        self.runtime.freeValue(state.items.items[index]);
                        state.items.items[index] = try self.makeIndexedContainer(state.allocator, indices[1]);
                    }
                    try self.setIndexedValue(&state.items.items[index], state.allocator, indices[1..], new_value);
                },
                .map => {
                    const state = @as(*collections.MapState, @ptrCast(@alignCast(object.ptr)));
                    if (!state.allocated) {
                        state.allocated = true;
                    }
                    const key = try self.mapKey(indices[0]);
                    const slot_index = try self.runtime.ensureMapEntryIndex(state, key);
                    if (indices.len == 1) {
                        self.runtime.freeValue(state.entries.items[slot_index].value);
                        state.entries.items[slot_index].value = try self.runtime.cloneValueToAllocator(state.allocator, new_value);
                        return;
                    }
                    if (!Runtime.isContainerValue(state.entries.items[slot_index].value)) {
                        self.runtime.freeValue(state.entries.items[slot_index].value);
                        state.entries.items[slot_index].value = try self.makeIndexedContainer(state.allocator, indices[1]);
                    }
                    try self.setIndexedValue(&state.entries.items[slot_index].value, state.allocator, indices[1..], new_value);
                },
                else => unreachable,
            },
            else => unreachable,
        }
    }

    const NumericValue = struct {
        kind: NumericKind,
        integer: i64 = 0,
        float: f64 = 0,
        compare: f64 = 0,
    };

    const NumericKind = enum {
        integer,
        float,
    };

    fn numericInteger(value_in: i64) NumericValue {
        return .{
            .kind = .integer,
            .integer = value_in,
            .compare = @as(f64, @floatFromInt(value_in)),
        };
    }

    fn numericFloat(value_in: f64) NumericValue {
        return .{
            .kind = .float,
            .float = value_in,
            .compare = value_in,
        };
    }

    fn numericValue(self: *Runner, v: value.Value) !NumericValue {
        if (self.strictMode()) {
            return switch (v) {
                .none => numericInteger(0),
                .integer => |i| numericInteger(i),
                .float => |f| numericFloat(f),
                else => error.StrictTypeMismatch,
            };
        }

        return switch (v) {
            .none => numericInteger(0),
            .boolean => |b| numericInteger(if (b) 1 else 0),
            .integer => |i| numericInteger(i),
            .float => |f| numericFloat(f),
            .string => |s| blk: {
                if (std.fmt.parseInt(i64, s, 10)) |i| {
                    break :blk numericInteger(i);
                } else |_| {
                    const f = std.fmt.parseFloat(f64, s) catch 0;
                    break :blk numericFloat(f);
                }
            },
            .cookie => |cookie| blk: {
                if (std.fmt.parseInt(i64, cookie.value, 10)) |i| {
                    break :blk numericInteger(i);
                } else |_| {
                    const f = std.fmt.parseFloat(f64, cookie.value) catch 0;
                    break :blk numericFloat(f);
                }
            },
            .object => numericInteger(0),
        };
    }

    fn numericResult(value_in: NumericValue) value.Value {
        return switch (value_in.kind) {
            .integer => .{ .integer = value_in.integer },
            .float => .{ .float = value_in.float },
        };
    }

    fn numericAggregate(self: *Runner, args: []value.Value, use_max: bool) !value.Value {
        if (args.len == 0) return .{ .integer = 0 };

        var best = try self.numericValue(args[0]);
        for (args[1..]) |arg| {
            const candidate = try self.numericValue(arg);
            const replace = if (use_max)
                candidate.compare > best.compare or (candidate.compare == best.compare and best.kind == .integer and candidate.kind == .float)
            else
                candidate.compare < best.compare or (candidate.compare == best.compare and best.kind == .integer and candidate.kind == .float);
            if (replace) best = candidate;
        }

        return numericResult(best);
    }

    fn randBound(self: *Runner, v: value.Value) !i64 {
        if (self.strictMode()) return try self.strictNumericValue(v);
        return toInt(v);
    }

    fn responseText(self: *Runner, v: value.Value) ![]const u8 {
        if (self.strictMode()) return try self.strictStringValue(v);
        return try self.valueText(v);
    }

    fn regexText(self: *Runner, v: value.Value) ![]const u8 {
        if (self.strictMode()) return try self.strictStringValue(v);
        return try self.valueText(v);
    }

    fn compareValues(self: *Runner, lhs: value.Value, rhs: value.Value, strict: bool) anyerror!std.math.Order {
        if (!strict) {
            if (lhs == .string or lhs == .cookie or lhs == .object or rhs == .string or rhs == .cookie or rhs == .object) {
                const l = try self.valueText(lhs);
                const r = try self.valueText(rhs);
                return std.mem.order(u8, l, r);
            }
            const l = toFloatStatic(lhs);
            const r = toFloatStatic(rhs);
            return std.math.order(l, r);
        }

        const lhs_kind = strictCompareKind(lhs);
        const rhs_kind = strictCompareKind(rhs);
        if (lhs_kind == .invalid or rhs_kind == .invalid) return error.StrictTypeMismatch;
        const kind: StrictCompareKind = if (lhs_kind == .none) rhs_kind else if (rhs_kind == .none) lhs_kind else if (lhs_kind == rhs_kind) lhs_kind else return error.StrictTypeMismatch;

        return switch (kind) {
            .none => .eq,
            .string => std.mem.order(u8, try self.strictStringValue(lhs), try self.strictStringValue(rhs)),
            .numeric => std.math.order(try self.strictFloatValue(lhs), try self.strictFloatValue(rhs)),
            .boolean => blk: {
                const l = try self.boolValue(lhs);
                const r = try self.boolValue(rhs);
                break :blk if (l == r) .eq else if (!l and r) .lt else .gt;
            },
            .invalid => error.StrictTypeMismatch,
        };
    }

    const StrictCompareKind = enum {
        none,
        string,
        numeric,
        boolean,
        invalid,
    };

    fn strictCompareKind(v: value.Value) StrictCompareKind {
        return switch (v) {
            .none => .none,
            .string => .string,
            .integer, .float => .numeric,
            .boolean => .boolean,
            else => .invalid,
        };
    }

    fn toFloatStatic(v: value.Value) f64 {
        return switch (v) {
            .none => 0,
            .boolean => |b| if (b) 1 else 0,
            .integer => |i| @as(f64, @floatFromInt(i)),
            .float => |f| f,
            .string => |s| std.fmt.parseFloat(f64, s) catch 0,
            .cookie => |cookie| std.fmt.parseFloat(f64, cookie.value) catch 0,
            .object => 0,
        };
    }

    fn currentScriptName(self: *Runner) []const u8 {
        if (self.current_path.len != 0) return self.current_path;
        return self.runtime.currentScriptPath();
    }

    fn pseudoProperty(self: *Runner, name: []const u8) value.Value {
        _ = self;
        if (std.ascii.eqlIgnoreCase(name, "eof") or std.ascii.eqlIgnoreCase(name, "bof")) {
            return .{ .boolean = true };
        }
        if (std.ascii.eqlIgnoreCase(name, "count") or std.ascii.eqlIgnoreCase(name, "qty") or std.ascii.eqlIgnoreCase(name, "autoid") or std.ascii.eqlIgnoreCase(name, "productid") or std.ascii.eqlIgnoreCase(name, "orderid") or std.ascii.eqlIgnoreCase(name, "quantity")) {
            return .{ .integer = 0 };
        }
        if (std.ascii.eqlIgnoreCase(name, "unitcost") or std.ascii.eqlIgnoreCase(name, "subtotal")) {
            return .{ .float = 0 };
        }
        if (std.ascii.eqlIgnoreCase(name, "modelname") or std.ascii.eqlIgnoreCase(name, "description") or std.ascii.eqlIgnoreCase(name, "productimage") or std.ascii.eqlIgnoreCase(name, "title") or std.ascii.eqlIgnoreCase(name, "script")) {
            return .{ .string = "" };
        }
        return .{ .none = {} };
    }

    fn evaluateIdentifier(self: *Runner, name: []const u8, execute: bool) anyerror!value.Value {
        if (std.ascii.eqlIgnoreCase(name, "true")) return .{ .boolean = true };
        if (std.ascii.eqlIgnoreCase(name, "false")) return .{ .boolean = false };
        if (std.ascii.eqlIgnoreCase(name, "null") or std.ascii.eqlIgnoreCase(name, "none")) return .{ .none = {} };
        if (!execute) return .{ .none = {} };
        if (self.runtime.getVariable(name)) |v| return v;
        return .{ .none = {} };
    }

    fn runExpressionChunk(self: *Runner, writer: anytype) anyerror!Flow {
        const v = try self.parseExpression(true, writer);
        self.skipEols();
        try self.emitValue(writer, v);
        self.resetTemps();
        return .normal;
    }

    fn runBlockChunk(self: *Runner, writer: anytype) anyerror!Flow {
        while (true) {
            self.skipEols();
            if (self.atEnd()) return .normal;
            if (self.isIfBranchStop() != null or self.isEndWhileStop() != null or self.isEndForStop() != null or self.isEndFunctionStop() != null) {
                return .normal;
            }

            const flow = try self.parseStatement(true, writer);
            switch (flow) {
                .normal => self.resetTemps(),
                else => return flow,
            }
        }
    }

    fn looksLikeAssignment(self: *const Runner) bool {
        const first = self.peek(0) orelse return false;
        if (first.kind != .identifier) return false;

        var cursor: usize = 1;
        while (self.peek(cursor)) |token| {
            if (token.kind != .l_bracket) break;
            cursor += 1;
            var depth: usize = 1;
            while (self.peek(cursor)) |inner| {
                switch (inner.kind) {
                    .l_bracket => depth += 1,
                    .r_bracket => {
                        depth -= 1;
                        cursor += 1;
                        if (depth == 0) break;
                        continue;
                    },
                    else => {},
                }
                cursor += 1;
            }
            if (depth != 0) return false;
        }

        const next = self.peek(cursor) orelse return false;
        return next.kind == .eq;
    }

    const AssignmentTarget = struct {
        name: []const u8,
        indices: []value.Value,
    };

    fn parseAssignmentTarget(self: *Runner, execute: bool, writer: anytype) anyerror!AssignmentTarget {
        const name = try self.consumeIdentifier();
        var indices: std.ArrayList(value.Value) = .empty;
        errdefer indices.deinit(self.tmpAllocator());

        while (self.matchOperator(.l_bracket)) {
            self.pos += 1;
            const index = try self.parseExpression(execute, writer);
            if (!self.matchOperator(.r_bracket)) return error.InvalidExpression;
            self.pos += 1;
            try indices.append(self.tmpAllocator(), index);
        }

        return .{
            .name = name,
            .indices = try indices.toOwnedSlice(self.tmpAllocator()),
        };
    }

    fn parseStatement(self: *Runner, execute: bool, writer: anytype) anyerror!Flow {
        self.skipEols();
        if (self.atEnd()) return .normal;

        if (self.matchIdentifier("if")) {
            return try self.parseIfStatement(execute, writer);
        }
        if (self.matchIdentifier("while")) {
            return try self.parseWhileStatement(execute, writer);
        }
        if (self.matchIdentifier("for")) {
            return try self.parseForStatement(execute, writer);
        }
        if (self.matchIdentifier("function")) {
            return try self.parseFunctionDefinition(execute, writer);
        }
        if (self.matchIdentifier("include")) {
            return try self.parseIncludeStatement(execute, writer);
        }
        if (self.matchIdentifier("print")) {
            return try self.parsePrintStatement(execute, writer);
        }
        if (self.matchIdentifier("return")) {
            return try self.parseReturnStatement(execute, writer);
        }
        if (self.matchIdentifier("exit")) {
            return try self.parseExitStatement(execute, writer);
        }
        if (self.matchIdentifier("break") or self.matchIdentifier("continue")) {
            self.pos += 1;
            return .normal;
        }

        if (self.looksLikeAssignment()) {
            return try self.parseAssignment(execute, writer);
        }

        _ = try self.parseExpression(execute, writer);
        self.skipEols();
        return .normal;
    }

    fn parsePrintStatement(self: *Runner, execute: bool, writer: anytype) anyerror!Flow {
        try self.consumeKeyword("print");
        const printed_value = try self.parseExpression(execute, writer);
        self.skipEols();
        if (execute) {
            try self.emitValue(writer, printed_value);
        }
        return .normal;
    }

    fn parseIncludeStatement(self: *Runner, execute: bool, writer: anytype) anyerror!Flow {
        try self.consumeKeyword("include");
        const include_path_value = try self.parseExpression(execute, writer);
        self.skipEols();
        if (!execute) return .normal;

        const include_path = try self.valueText(include_path_value);
        try self.includePath(include_path, writer);
        return .normal;
    }

    fn parseReturnStatement(self: *Runner, execute: bool, writer: anytype) anyerror!Flow {
        try self.consumeKeyword("return");
        self.skipEols();
        if (self.atEnd() or self.matchIdentifier("end") or self.matchIdentifier("else") or self.matchIdentifier("elseif")) {
            return if (execute) .{ .return_value = .{ .none = {} } } else .normal;
        }
        const return_value = try self.parseExpression(execute, writer);
        self.skipEols();
        if (execute) return .{ .return_value = return_value };
        return .normal;
    }

    fn parseExitStatement(self: *Runner, execute: bool, writer: anytype) anyerror!Flow {
        try self.consumeKeyword("exit");
        _ = writer;
        if (self.matchOperator(.l_paren)) {
            self.pos += 1;
            if (!self.matchOperator(.r_paren)) return error.InvalidExpression;
            self.pos += 1;
        }
        self.skipEols();
        if (execute) return .exit;
        return .normal;
    }

    fn parseAssignment(self: *Runner, execute: bool, writer: anytype) anyerror!Flow {
        const target = try self.parseAssignmentTarget(execute, writer);
        try self.consumeOperator(.eq);
        const assigned_value = try self.parseExpression(execute, writer);
        self.skipEols();
        if (execute) {
            if (target.indices.len == 0) {
                try self.runtime.setVariable(target.name, assigned_value);
            } else {
                const index = self.runtime.variableIndex(target.name) orelse blk: {
                    try self.runtime.variables.append(self.runtime.allocator, .{
                        .name = try canonicalName(self.runtime.allocator, target.name),
                        .value = .{ .none = {} },
                    });
                    break :blk self.runtime.variables.items.len - 1;
                };
                try self.setIndexedValue(&self.runtime.variables.items[index].value, self.runtime.allocator, target.indices, assigned_value);
            }
        }
        return .normal;
    }

    fn parseIfStatement(self: *Runner, execute: bool, writer: anytype) anyerror!Flow {
        try self.consumeKeyword("if");

        if (!execute) {
            _ = try self.parseExpression(false, writer);
            self.maybeConsumeThen();
            self.skipEols();
            const body = try self.executeUntil(.if_branch, false, writer);
            switch (body) {
                .flow => |f| return f,
                .stop => |stop| switch (stop) {
                    .elseif_branch => {
                        try self.consumeKeyword("elseif");
                        _ = try self.parseExpression(false, writer);
                        self.maybeConsumeThen();
                        self.skipEols();
                        return try self.skipIfTail(writer);
                    },
                    .else_branch => {
                        try self.consumeKeyword("else");
                        self.skipEols();
                        const tail = try self.executeUntil(.end_if, false, writer);
                        switch (tail) {
                            .flow => |f| return f,
                            .stop => {
                                try self.consumeEndIf();
                                return .normal;
                            },
                        }
                    },
                    .end_if => {
                        try self.consumeEndIf();
                        return .normal;
                    },
                    .eof => return .normal,
                    else => return .normal,
                },
            }
        }

        var first_branch = true;
        while (true) {
            if (first_branch) {
                const cond = try self.parseExpression(true, writer);
                self.maybeConsumeThen();
                self.skipEols();
                first_branch = false;

                const cond_truth = try self.boolValue(cond);
                const body = try self.executeUntil(.if_branch, cond_truth, writer);
                switch (body) {
                    .flow => |f| return f,
                    .stop => |stop| switch (stop) {
                        .end_if => {
                            try self.consumeEndIf();
                            return .normal;
                        },
                        .elseif_branch, .else_branch => {
                            return try self.skipIfTail(writer);
                        },
                        else => return .normal,
                    },
                }
            } else if (self.matchIdentifier("elseif")) {
                try self.consumeKeyword("elseif");
                const cond = try self.parseExpression(true, writer);
                self.maybeConsumeThen();
                self.skipEols();
                const cond_truth = try self.boolValue(cond);
                const body = try self.executeUntil(.if_branch, cond_truth, writer);
                switch (body) {
                    .flow => |f| return f,
                    .stop => |stop| switch (stop) {
                        .elseif_branch => continue,
                        .else_branch => {
                            try self.consumeKeyword("else");
                            self.skipEols();
                            const else_body = try self.executeUntil(.end_if, true, writer);
                            switch (else_body) {
                                .flow => |f| return f,
                                .stop => {
                                    try self.consumeEndIf();
                                    return .normal;
                                },
                            }
                        },
                        .end_if => {
                            try self.consumeEndIf();
                            return .normal;
                        },
                        else => return .normal,
                    },
                }
            } else if (self.matchIdentifier("else")) {
                try self.consumeKeyword("else");
                self.skipEols();
                const else_body = try self.executeUntil(.end_if, true, writer);
                switch (else_body) {
                    .flow => |f| return f,
                    .stop => {
                        try self.consumeEndIf();
                        return .normal;
                    },
                }
            } else if (self.matchEndPair("if")) {
                try self.consumeEndIf();
                return .normal;
            } else {
                return .normal;
            }
        }
    }

    fn skipIfTail(self: *Runner, writer: anytype) anyerror!Flow {
        while (true) {
            if (self.matchIdentifier("elseif")) {
                try self.consumeKeyword("elseif");
                _ = try self.parseExpression(false, writer);
                self.maybeConsumeThen();
                self.skipEols();
                const body = try self.executeUntil(.if_branch, false, writer);
                switch (body) {
                    .flow => |f| return f,
                    .stop => |stop| switch (stop) {
                        .elseif_branch => continue,
                        .else_branch => {
                            try self.consumeKeyword("else");
                            self.skipEols();
                            const tail = try self.executeUntil(.end_if, false, writer);
                            switch (tail) {
                                .flow => |f| return f,
                                .stop => {
                                    try self.consumeEndIf();
                                    return .normal;
                                },
                            }
                        },
                        .end_if => {
                            try self.consumeEndIf();
                            return .normal;
                        },
                        else => return .normal,
                    },
                }
            } else if (self.matchIdentifier("else")) {
                try self.consumeKeyword("else");
                self.skipEols();
                const tail = try self.executeUntil(.end_if, false, writer);
                switch (tail) {
                    .flow => |f| return f,
                    .stop => {
                        try self.consumeEndIf();
                        return .normal;
                    },
                }
            } else if (self.matchEndPair("if")) {
                try self.consumeEndIf();
                return .normal;
            } else {
                return .normal;
            }
        }
    }

    fn parseWhileStatement(self: *Runner, execute: bool, writer: anytype) anyerror!Flow {
        try self.consumeKeyword("while");
        const condition_start = self.pos;
        const cond = try self.parseExpression(execute, writer);
        self.maybeConsumeThen();
        self.skipEols();
        const body_start = self.pos;

        const cond_truth = if (execute) try self.boolValue(cond) else false;
        if (!execute or !cond_truth) {
            self.pos = body_start;
            const skip = try self.executeUntil(.end_while, false, writer);
            switch (skip) {
                .flow => |f| return f,
                .stop => {
                    try self.consumeEndWhile();
                    return .normal;
                },
            }
        }

        while (true) {
            self.pos = body_start;
            const body = try self.executeUntil(.end_while, true, writer);
            switch (body) {
                .flow => |f| return f,
                .stop => {
                    try self.consumeEndWhile();
                },
            }

            self.pos = condition_start;
            const next_cond = try self.parseExpression(true, writer);
            self.maybeConsumeThen();
            self.skipEols();
            const next_truth = try self.boolValue(next_cond);
            if (!next_truth) {
                self.pos = body_start;
                const skip = try self.executeUntil(.end_while, false, writer);
                switch (skip) {
                    .flow => |f| return f,
                    .stop => {
                        try self.consumeEndWhile();
                        return .normal;
                    },
                }
            }
        }
    }

    fn parseForStatement(self: *Runner, execute: bool, writer: anytype) anyerror!Flow {
        try self.consumeKeyword("for");
        const name = try self.consumeIdentifier();
        try self.consumeOperator(.eq);
        const start_value = try self.parseExpression(execute, writer);
        if (!self.matchIdentifier("to")) return error.InvalidExpression;
        self.pos += 1;
        const end_value = try self.parseExpression(execute, writer);

        var step_value: value.Value = .{ .integer = 1 };
        if (self.matchIdentifier("step")) {
            self.pos += 1;
            step_value = try self.parseExpression(execute, writer);
        }

        self.skipEols();
        const body_start = self.pos;

        if (!execute) {
            const skipped = try self.executeUntil(.end_for, false, writer);
            switch (skipped) {
                .flow => |f| return f,
                .stop => |stop| switch (stop) {
                    .end_for => {
                        try self.consumeEndFor();
                        return .normal;
                    },
                    else => return .normal,
                },
            }
        }

        const start_int = try self.strictNumericValue(start_value);
        const end_int = try self.strictNumericValue(end_value);
        const step_int = try self.strictNumericValue(step_value);
        if (step_int == 0) return error.InvalidExpression;

        var current_value = start_int;
        const forward = step_int > 0;
        var ran_any = false;
        while (if (forward) current_value <= end_int else current_value >= end_int) {
            ran_any = true;
            try self.runtime.setVariable(name, .{ .integer = current_value });
            self.pos = body_start;
            const body = try self.executeUntil(.end_for, true, writer);
            switch (body) {
                .flow => |f| return f,
                .stop => |stop| switch (stop) {
                    .end_for => try self.consumeEndFor(),
                    else => return .normal,
                },
            }
            current_value += step_int;
        }

        if (!ran_any) {
            self.pos = body_start;
            const skipped = try self.executeUntil(.end_for, false, writer);
            switch (skipped) {
                .flow => |f| return f,
                .stop => |stop| switch (stop) {
                    .end_for => try self.consumeEndFor(),
                    else => return .normal,
                },
            }
        }

        return .normal;
    }

    fn parseFunctionDefinition(self: *Runner, execute: bool, writer: anytype) anyerror!Flow {
        try self.consumeKeyword("function");
        const name = try self.consumeIdentifier();
        var params = std.ArrayList([]u8).empty;
        defer params.deinit(self.runtime.allocator);

        if (self.peek(0)) |token| {
            if (token.kind == .l_paren) {
                self.pos += 1;
                self.skipEols();
                if (!self.matchOperator(.r_paren)) {
                    while (true) {
                        const param_name = try self.consumeIdentifier();
                        try params.append(self.runtime.allocator, try canonicalName(self.runtime.allocator, param_name));
                        self.skipEols();
                        if (self.matchOperator(.comma)) {
                            self.pos += 1;
                            self.skipEols();
                            continue;
                        }
                        break;
                    }
                }
                if (!self.matchOperator(.r_paren)) return error.InvalidExpression;
                self.pos += 1;
            }
        }

        self.skipEols();
        const body_start = self.positionSource();

        const body = try self.executeUntil(.end_function, false, writer);
        switch (body) {
            .flow => |f| return f,
            .stop => {
                const body_end = self.positionSource();
                if (execute) {
                    try self.runtime.registerFunction(
                        name,
                        try params.toOwnedSlice(self.runtime.allocator),
                        self.source[body_start..body_end],
                        self.current_path,
                    );
                }
                try self.consumeEndFunction();
                return .normal;
            },
        }
    }

    fn positionSource(self: *Runner) usize {
        if (self.atEnd()) return self.source.len;
        return self.current().start;
    }

    fn executeUntil(self: *Runner, stop: BlockStop, execute: bool, writer: anytype) anyerror!BlockResult {
        while (true) {
            self.skipEols();
            if (self.atEnd()) return .{ .stop = .eof };
            if (self.checkStop(stop)) |found| return .{ .stop = found };
            const flow = try self.parseStatement(execute, writer);
            switch (flow) {
                .normal => self.resetTemps(),
                else => return .{ .flow = flow },
            }
        }
    }

    fn checkStop(self: *const Runner, stop: BlockStop) ?BlockStop {
        return switch (stop) {
            .eof => if (self.atEnd()) .eof else null,
            .if_branch => self.isIfBranchStop(),
            .elseif_branch => self.isIfBranchStop(),
            .end_if => if (self.matchEndPair("if")) .end_if else null,
            .end_while => self.isEndWhileStop(),
            .end_for => self.isEndForStop(),
            .end_function => self.isEndFunctionStop(),
            .else_branch => if (self.matchIdentifier("else")) .else_branch else null,
        };
    }

    fn parseExpression(self: *Runner, execute: bool, writer: anytype) anyerror!value.Value {
        return try self.parseBinary(0, execute, writer);
    }

    fn parseBinary(self: *Runner, min_prec: u8, execute: bool, writer: anytype) anyerror!value.Value {
        var lhs = try self.parsePrefix(execute, writer);
        while (true) {
            self.skipEols();
            const op_info = self.peekBinaryOperator() orelse break;
            if (op_info.prec < min_prec) break;
            self.pos += op_info.consume;
            const rhs = try self.parseBinary(op_info.prec + 1, execute, writer);
            lhs = try self.applyBinary(op_info, lhs, rhs, execute);
        }
        return lhs;
    }

    const BinaryOperator = struct {
        op: TokenKind,
        prec: u8,
        consume: usize = 1,
        keyword: ?[]const u8 = null,
    };

    fn peekBinaryOperator(self: *const Runner) ?BinaryOperator {
        const token = self.peek(0) orelse return null;
        return switch (token.kind) {
            .plus => .{ .op = .plus, .prec = 40 },
            .minus => .{ .op = .minus, .prec = 40 },
            .amp => .{ .op = .amp, .prec = 35 },
            .star => .{ .op = .star, .prec = 50 },
            .slash => .{ .op = .slash, .prec = 50 },
            .eq => .{ .op = .eq, .prec = 30 },
            .lt => .{ .op = .lt, .prec = 30 },
            .gt => .{ .op = .gt, .prec = 30 },
            .lte => .{ .op = .lte, .prec = 30 },
            .gte => .{ .op = .gte, .prec = 30 },
            .neq => .{ .op = .neq, .prec = 30 },
            .identifier => blk: {
                const t = self.text(token);
                if (std.ascii.eqlIgnoreCase(t, "and")) break :blk .{ .op = .identifier, .prec = 20, .keyword = "and" };
                if (std.ascii.eqlIgnoreCase(t, "or")) break :blk .{ .op = .identifier, .prec = 10, .keyword = "or" };
                break :blk null;
            },
            else => null,
        };
    }

    fn parsePrefix(self: *Runner, execute: bool, writer: anytype) anyerror!value.Value {
        self.skipEols();
        const token = self.peek(0) orelse return .{ .none = {} };
        switch (token.kind) {
            .number => {
                self.pos += 1;
                const num_text = self.text(token);
                if (std.mem.indexOfScalar(u8, num_text, '.')) |_| {
                    return .{ .float = std.fmt.parseFloat(f64, num_text) catch 0 };
                }
                return .{ .integer = std.fmt.parseInt(i64, num_text, 10) catch 0 };
            },
            .string => {
                self.pos += 1;
                if (!execute) return .{ .none = {} };
                return .{ .string = try self.decodeString(token) };
            },
            .identifier => {
                const ident_text = self.text(token);
                if (std.ascii.eqlIgnoreCase(ident_text, "not")) {
                    self.pos += 1;
                    const rhs = try self.parseBinary(60, execute, writer);
                    const rhs_truth = if (execute) try self.boolValue(rhs) else toBool(rhs);
                    return .{ .boolean = !rhs_truth };
                }
                if (std.ascii.eqlIgnoreCase(ident_text, "new")) {
                    self.pos += 1;
                    const type_name = try self.consumeIdentifier();
                    var args: []value.Value = &.{};
                    if (self.matchOperator(.l_paren)) {
                        args = try self.parseCallArguments(execute, writer);
                    }
                    if (std.ascii.eqlIgnoreCase(type_name, "cookie")) {
                        return try self.newCookieValue(args, execute);
                    }
                    if (std.ascii.eqlIgnoreCase(type_name, "file")) {
                        return try self.newFileValue(args, execute);
                    }
                if (std.ascii.eqlIgnoreCase(type_name, "array")) {
                    if (!execute) return .{ .none = {} };
                    return try self.runtime.createArrayValue(self.tmpAllocator(), 1, args);
                }
                    if (std.ascii.eqlIgnoreCase(type_name, "map")) {
                        if (!execute) return .{ .none = {} };
                        var pairs: std.ArrayList(Runtime.MapPair) = .empty;
                        defer pairs.deinit(self.tmpAllocator());
                        var i: usize = 0;
                        while (i + 1 < args.len) : (i += 2) {
                            const key = try self.mapKey(args[i]);
                            try pairs.append(self.tmpAllocator(), .{
                                .key = key,
                                .value = args[i + 1],
                            });
                        }
                        return try self.runtime.createMapValue(self.tmpAllocator(), pairs.items);
                    }
                    if (std.ascii.eqlIgnoreCase(type_name, "connection")) {
                        return try self.newConnectionValue(args, execute);
                    }
                    if (std.ascii.eqlIgnoreCase(type_name, "recordset")) {
                        return try self.newRecordsetValue(args, execute);
                    }
                    if (std.ascii.eqlIgnoreCase(type_name, "ddl")) {
                        return try self.newDdlValue(args, execute);
                    }
                    return .{ .none = {} };
                }
                self.pos += 1;
                if (self.matchOperator(.l_paren)) {
                    const args = try self.parseCallArguments(execute, writer);
                    var result = try self.callFunction(ident_text, args, execute, writer);
                    result = try self.parsePostfix(result, execute, writer);
                    return result;
                }
                var result = try self.evaluateIdentifier(ident_text, execute);
                result = try self.parsePostfix(result, execute, writer);
                return result;
            },
            .l_paren => {
                self.pos += 1;
                const inner = try self.parseExpression(execute, writer);
                if (!self.matchOperator(.r_paren)) return error.InvalidExpression;
                self.pos += 1;
                return inner;
            },
            .minus => {
                self.pos += 1;
                const rhs = try self.parseBinary(60, execute, writer);
                const rhs_int = if (execute and self.strictMode()) try self.strictNumericValue(rhs) else toInt(rhs);
                return .{ .integer = -rhs_int };
            },
            .plus => {
                self.pos += 1;
                return try self.parseBinary(60, execute, writer);
            },
            else => return .{ .none = {} },
        }
    }

    fn parsePostfix(self: *Runner, base: value.Value, execute: bool, writer: anytype) anyerror!value.Value {
        var result = base;
        while (true) {
            self.skipEols();
            const token = self.peek(0) orelse break;
            switch (token.kind) {
                .dot => {
                    self.pos += 1;
                    const prop = try self.consumeIdentifier();
                    if (self.matchOperator(.l_paren)) {
                        const args = try self.parseCallArguments(execute, writer);
                        result = try self.callMethod(result, prop, args, execute, writer);
                    } else {
                        result = self.propertyValue(result, prop);
                    }
                },
                .l_bracket => {
                    self.pos += 1;
                    const index_value = try self.parseExpression(execute, writer);
                    if (!self.matchOperator(.r_bracket)) return error.InvalidExpression;
                    self.pos += 1;
                    if (!execute) {
                        result = .{ .none = {} };
                    } else {
                        result = try self.indexValue(result, index_value);
                    }
                },
                else => break,
            }
        }
        return result;
    }

    fn parseCallArguments(self: *Runner, execute: bool, writer: anytype) anyerror![]value.Value {
        if (!self.matchOperator(.l_paren)) return error.InvalidExpression;
        self.pos += 1;
        self.skipEols();

        var args: std.ArrayList(value.Value) = .empty;
        errdefer args.deinit(self.tmpAllocator());

        if (!self.matchOperator(.r_paren)) {
            while (true) {
                const arg = try self.parseExpression(execute, writer);
                try args.append(self.tmpAllocator(), arg);
                self.skipEols();
                if (self.matchOperator(.comma)) {
                    self.pos += 1;
                    self.skipEols();
                    continue;
                }
                break;
            }
        }
        if (!self.matchOperator(.r_paren)) return error.InvalidExpression;
        self.pos += 1;
        return try args.toOwnedSlice(self.tmpAllocator());
    }

    fn callMethod(self: *Runner, base: value.Value, prop: []const u8, args: []value.Value, execute: bool, writer: anytype) anyerror!value.Value {
        if (!execute) return .{ .none = {} };
        if (base == .object) {
            switch (base.object.kind) {
                .file => {
                    const file = @as(*fileobj.FileState, @ptrCast(@alignCast(base.object.ptr)));
                    if (std.ascii.eqlIgnoreCase(prop, "read")) {
                        const count = if (args.len >= 1) blk: {
                            const n = if (self.strictMode()) try self.strictNumericValue(args[0]) else toInt(args[0]);
                            break :blk if (n <= 0) null else @as(usize, @intCast(n));
                        } else null;
                        return .{ .string = try fileobj.read(file, self.tmpAllocator(), self.runtime.io, count) };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "readln")) {
                        return .{ .string = try fileobj.readLine(file, self.tmpAllocator(), self.runtime.io) };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "write")) {
                        if (args.len >= 1) {
                            const data = try self.valueText(args[0]);
                            const length = if (args.len >= 2) blk: {
                                const n = if (self.strictMode()) try self.strictNumericValue(args[1]) else toInt(args[1]);
                                break :blk if (n <= 0) 0 else @as(usize, @intCast(n));
                            } else data.len;
                            return .{ .integer = try fileobj.write(file, self.tmpAllocator(), self.runtime.io, data, length) };
                        }
                        return .{ .integer = 0 };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "close")) {
                        fileobj.close(file, self.tmpAllocator(), self.runtime.io);
                        return .{ .none = {} };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "eof")) {
                        return .{ .boolean = fileobj.eof(file, self.runtime.io) };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "rewind")) {
                        fileobj.rewind(file, self.tmpAllocator());
                        return .{ .none = {} };
                    }
                },
                .recordset => {
                    const recordset = @as(*db.RecordsetState, @ptrCast(@alignCast(base.object.ptr)));
                    if (std.ascii.eqlIgnoreCase(prop, "next")) {
                        db.recordsetNext(recordset);
                        return .{ .none = {} };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "execute")) {
                        try db.recordsetExecute(recordset, self.runtime.allocator, args);
                        return .{ .none = {} };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "close")) {
                        return .{ .none = {} };
                    }
                },
                .ddl => {
                    const ddl = @as(*db.DdlState, @ptrCast(@alignCast(base.object.ptr)));
                    if (std.ascii.eqlIgnoreCase(prop, "execute")) {
                        try db.ddlExecute(ddl, self.runtime.allocator, args);
                        return .{ .none = {} };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "close")) {
                        return .{ .none = {} };
                    }
                },
                .connection => {
                    const connection = @as(*db.ConnectionState, @ptrCast(@alignCast(base.object.ptr)));
                    const status = db.connectionStatus(connection);
                    if (std.ascii.eqlIgnoreCase(prop, "close")) {
                        return .{ .none = {} };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "backend")) {
                        return .{ .string = dbspec.backendName(status.backend) };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "opened")) {
                        return .{ .integer = status.opened_at };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "last_used")) {
                        return .{ .integer = status.last_used_at };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "last_refresh")) {
                        return .{ .integer = status.last_refresh_at };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "refresh_count")) {
                        return .{ .integer = @intCast(status.refresh_count) };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "stale")) {
                        return .{ .boolean = status.stale };
                    }
                },
                .array, .map => {},
            }
        }
        if (std.ascii.eqlIgnoreCase(prop, "next") or std.ascii.eqlIgnoreCase(prop, "execute") or std.ascii.eqlIgnoreCase(prop, "close")) {
            return .{ .none = {} };
        }
        _ = writer;
        return self.propertyValue(base, prop);
    }

    fn propertyValue(self: *Runner, base: value.Value, prop: []const u8) value.Value {
        if (base == .none) return self.pseudoProperty(prop);
        if (base == .object) {
            switch (base.object.kind) {
                .file => {
                    const file = @as(*fileobj.FileState, @ptrCast(@alignCast(base.object.ptr)));
                    if (std.ascii.eqlIgnoreCase(prop, "name")) {
                        return fileobj.nameValue(file);
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "mode")) {
                        return fileobj.modeValue(file);
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "error")) {
                        return fileobj.errorValue(file);
                    }
                },
                .array => {
                    const state = @as(*collections.ArrayState, @ptrCast(@alignCast(base.object.ptr)));
                    if (std.ascii.eqlIgnoreCase(prop, "count")) {
                        if (!state.allocated) return .{ .integer = 0 };
                        return .{ .integer = @intCast(state.items.items.len) };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "allocated")) {
                        return .{ .boolean = state.allocated };
                    }
                },
                .map => {
                    const state = @as(*collections.MapState, @ptrCast(@alignCast(base.object.ptr)));
                    if (std.ascii.eqlIgnoreCase(prop, "count")) {
                        if (!state.allocated) return .{ .integer = 0 };
                        return .{ .integer = @intCast(state.entries.items.len) };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "allocated")) {
                        return .{ .boolean = state.allocated };
                    }
                },
                .recordset => {
                    const recordset = @as(*db.RecordsetState, @ptrCast(@alignCast(base.object.ptr)));
                    if (std.ascii.eqlIgnoreCase(prop, "eof")) {
                        return .{ .boolean = db.recordsetEof(recordset) };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "bof")) {
                        return .{ .boolean = db.recordsetBof(recordset) };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "count")) {
                        return .{ .integer = db.recordsetCount(recordset) };
                    }
                    return db.recordsetFieldValue(recordset, prop);
                },
                .connection => {
                    const connection = @as(*db.ConnectionState, @ptrCast(@alignCast(base.object.ptr)));
                    const status = db.connectionStatus(connection);
                    if (std.ascii.eqlIgnoreCase(prop, "backend")) {
                        return .{ .string = dbspec.backendName(status.backend) };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "opened")) {
                        return .{ .integer = status.opened_at };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "last_used")) {
                        return .{ .integer = status.last_used_at };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "last_refresh")) {
                        return .{ .integer = status.last_refresh_at };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "refresh_count")) {
                        return .{ .integer = @intCast(status.refresh_count) };
                    }
                    if (std.ascii.eqlIgnoreCase(prop, "stale")) {
                        return .{ .boolean = status.stale };
                    }
                },
                else => return .{ .none = {} },
            }
        }
        if (base == .string and std.ascii.eqlIgnoreCase(prop, "len")) {
            return .{ .integer = @intCast(base.string.len) };
        }
        if (base == .string) {
            return self.pseudoProperty(prop);
        }
        return self.pseudoProperty(prop);
    }

    fn callFunction(self: *Runner, name: []const u8, args: []value.Value, execute: bool, writer: anytype) anyerror!value.Value {
        if (!execute) return .{ .none = {} };

        if (std.ascii.eqlIgnoreCase(name, "header")) {
            if (args.len >= 2) {
                try self.runtime.setHeader(try self.responseText(args[0]), try self.responseText(args[1]));
            }
            return .{ .none = {} };
        }
        if (std.ascii.eqlIgnoreCase(name, "redirect")) {
            if (args.len >= 1) try self.runtime.redirect(try self.responseText(args[0]));
            return .{ .none = {} };
        }
        if (std.ascii.eqlIgnoreCase(name, "date")) {
            if (args.len == 3) {
                return .{ .integer = try self.dateFromYmd(args[0], args[1], args[2]) };
            }
            if (args.len == 1) {
                return .{ .integer = try date.parseText(try self.valueText(args[0]), Runtime.currentUnixSeconds()) };
            }
            return error.InvalidDate;
        }
        if (std.ascii.eqlIgnoreCase(name, "formatdate")) {
            if (args.len >= 2) {
                return .{ .string = try date.formatDate(self.tmpAllocator(), try self.dateSeconds(args[0]), try self.valueText(args[1])) };
            }
            return error.InvalidDate;
        }
        if (std.ascii.eqlIgnoreCase(name, "regexmatch") or std.ascii.eqlIgnoreCase(name, "preg_match")) {
            if (args.len >= 2) {
                return .{ .boolean = try regex.isMatch(self.runtime.allocator, try self.regexText(args[0]), try self.regexText(args[1])) };
            }
            return .{ .boolean = false };
        }
        if (std.ascii.eqlIgnoreCase(name, "regexvalid")) {
            if (args.len >= 1) {
                return .{ .boolean = try regex.isValid(try self.regexText(args[0])) };
            }
            return .{ .boolean = false };
        }
        if (std.ascii.eqlIgnoreCase(name, "regexreplace") or std.ascii.eqlIgnoreCase(name, "preg_replace")) {
            if (args.len >= 3) {
                return .{ .string = try regex.replaceAll(self.tmpAllocator(), try self.regexText(args[0]), try self.regexText(args[1]), try self.regexText(args[2])) };
            }
            return .{ .string = "" };
        }
        if (std.ascii.eqlIgnoreCase(name, "regexextract") or std.ascii.eqlIgnoreCase(name, "regexcapture")) {
            if (args.len >= 2) {
                const group_selector = if (args.len >= 3) try self.regexText(args[2]) else null;
                return .{ .string = try regex.extractFirst(self.tmpAllocator(), try self.regexText(args[0]), try self.regexText(args[1]), group_selector) };
            }
            return .{ .string = "" };
        }
        if (std.ascii.eqlIgnoreCase(name, "setcookie")) {
            if (args.len >= 1) {
                const spec = switch (args[0]) {
                    .cookie => |cookie| cookie,
                    else => response.CookieSpec{
                        .name = try self.responseText(args[0]),
                        .value = if (args.len >= 2) try self.responseText(args[1]) else "",
                        .path = if (args.len >= 3) try self.responseText(args[2]) else null,
                        .domain = if (args.len >= 4) try self.responseText(args[3]) else null,
                        .expires = if (args.len >= 5) try self.runtime.cookieExpiryText(self.tmpAllocator(), args[4]) else null,
                        .secure = if (args.len >= 6) try self.boolValue(args[5]) else false,
                    },
                };
                try self.runtime.setCookie(spec);
            }
            return .{ .none = {} };
        }
        if (std.ascii.eqlIgnoreCase(name, "now")) {
            return .{ .integer = Runtime.currentUnixSeconds() };
        }
        if (std.ascii.eqlIgnoreCase(name, "addseconds")) {
            if (args.len >= 2) return .{ .integer = toInt(args[0]) + toInt(args[1]) };
            if (args.len >= 1) return .{ .integer = toInt(args[0]) + 1 };
            return .{ .integer = Runtime.currentUnixSeconds() + 1 };
        }
        if (std.ascii.eqlIgnoreCase(name, "addminutes")) {
            if (args.len >= 2) return .{ .integer = toInt(args[0]) + (toInt(args[1]) * 60) };
            if (args.len >= 1) return .{ .integer = toInt(args[0]) + 60 };
            return .{ .integer = Runtime.currentUnixSeconds() + 60 };
        }
        if (std.ascii.eqlIgnoreCase(name, "addhours")) {
            if (args.len >= 2) return .{ .integer = toInt(args[0]) + (toInt(args[1]) * 60 * 60) };
            if (args.len >= 1) return .{ .integer = toInt(args[0]) + 60 * 60 };
            return .{ .integer = Runtime.currentUnixSeconds() + 60 * 60 };
        }
        if (std.ascii.eqlIgnoreCase(name, "max")) {
            return try self.numericAggregate(args, true);
        }
        if (std.ascii.eqlIgnoreCase(name, "min")) {
            return try self.numericAggregate(args, false);
        }
        if (std.ascii.eqlIgnoreCase(name, "rand")) {
            if (args.len >= 2) return .{ .integer = self.runtime.randomIntRange(try self.randBound(args[0]), try self.randBound(args[1])) };
            if (args.len >= 1) return .{ .integer = self.runtime.randomIntRange(0, try self.randBound(args[0])) };
            return .{ .integer = self.runtime.randomIntRange(0, std.math.maxInt(i64)) };
        }
        if (std.ascii.eqlIgnoreCase(name, "allocated")) {
            if (args.len >= 1) {
                if (Runtime.arrayStateFromValue(args[0])) |state| {
                    return .{ .boolean = state.allocated };
                }
                if (Runtime.mapStateFromValue(args[0])) |state| {
                    return .{ .boolean = state.allocated };
                }
            }
            return .{ .boolean = false };
        }
        if (std.ascii.eqlIgnoreCase(name, "size")) {
            if (args.len >= 1) {
                if (Runtime.arrayStateFromValue(args[0])) |state| {
                    if (!state.allocated) return .{ .integer = 0 };
                    return .{ .integer = @intCast(state.items.items.len) };
                }
                if (Runtime.mapStateFromValue(args[0])) |state| {
                    if (!state.allocated) return .{ .integer = 0 };
                    return .{ .integer = @intCast(state.entries.items.len) };
                }
            }
            return .{ .integer = 0 };
        }
        if (std.ascii.eqlIgnoreCase(name, "shape")) {
            if (args.len >= 1) {
                if (Runtime.arrayStateFromValue(args[0])) |state| {
                    if (!state.allocated) return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                    const item = value.Value{ .integer = @intCast(state.items.items.len) };
                    return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{item});
                }
            }
            return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
        }
        if (std.ascii.eqlIgnoreCase(name, "lbound")) {
            if (args.len >= 1) {
                if (Runtime.arrayStateFromValue(args[0])) |state| {
                    if (!state.allocated) return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                    const item = value.Value{ .integer = state.lower_bound };
                    return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{item});
                }
            }
            return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
        }
        if (std.ascii.eqlIgnoreCase(name, "ubound")) {
            if (args.len >= 1) {
                if (Runtime.arrayStateFromValue(args[0])) |state| {
                    if (!state.allocated) return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                    const upper = state.lower_bound + @as(i64, @intCast(state.items.items.len)) - 1;
                    const item = value.Value{ .integer = upper };
                    return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{item});
                }
            }
            return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
        }
        if (std.ascii.eqlIgnoreCase(name, "keys")) {
            if (args.len >= 1) {
                if (Runtime.mapStateFromValue(args[0])) |state| {
                    if (!state.allocated) return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                    var items: std.ArrayList(value.Value) = .empty;
                    defer items.deinit(self.tmpAllocator());
                    for (state.entries.items) |entry| {
                        try items.append(self.tmpAllocator(), .{ .string = entry.key });
                    }
                    return try self.runtime.createArrayValue(self.tmpAllocator(), 1, items.items);
                }
            }
            return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
        }
        if (std.ascii.eqlIgnoreCase(name, "values")) {
            if (args.len >= 1) {
                if (Runtime.mapStateFromValue(args[0])) |state| {
                    if (!state.allocated) return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                    var items: std.ArrayList(value.Value) = .empty;
                    defer items.deinit(self.tmpAllocator());
                    for (state.entries.items) |entry| {
                        try items.append(self.tmpAllocator(), entry.value);
                    }
                    return try self.runtime.createArrayValue(self.tmpAllocator(), 1, items.items);
                }
                if (Runtime.arrayStateFromValue(args[0])) |state| {
                    if (!state.allocated) return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                    return try self.runtime.createArrayValue(self.tmpAllocator(), 1, state.items.items);
                }
            }
            return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
        }
        if (std.ascii.eqlIgnoreCase(name, "contains")) {
            if (args.len >= 2) {
                if (Runtime.mapStateFromValue(args[0])) |state| {
                    if (!state.allocated) return .{ .boolean = false };
                    const key = try self.mapKey(args[1]);
                    for (state.entries.items) |entry| {
                        if (std.mem.eql(u8, entry.key, key)) return .{ .boolean = true };
                    }
                    return .{ .boolean = false };
                }
                if (Runtime.arrayStateFromValue(args[0])) |state| {
                    if (!state.allocated) return .{ .boolean = false };
                    const needle = try self.valueText(args[1]);
                    for (state.items.items) |item| {
                        if (std.mem.eql(u8, try self.valueText(item), needle)) return .{ .boolean = true };
                    }
                }
            }
            return .{ .boolean = false };
        }
        if (std.ascii.eqlIgnoreCase(name, "remove")) {
            if (args.len >= 2) {
                if (Runtime.mapStateFromValue(args[0])) |state| {
                    if (!state.allocated) return .{ .boolean = false };
                    const key = try self.mapKey(args[1]);
                    var index: usize = 0;
                    while (index < state.entries.items.len) : (index += 1) {
                        if (std.mem.eql(u8, state.entries.items[index].key, key)) {
                            self.runtime.freeValue(state.entries.items[index].value);
                            state.allocator.free(state.entries.items[index].key);
                            _ = state.entries.orderedRemove(index);
                            return .{ .boolean = true };
                        }
                    }
                    return .{ .boolean = false };
                }
            }
            return .{ .boolean = false };
        }
        if (std.ascii.eqlIgnoreCase(name, "move_alloc")) {
            if (args.len >= 2) {
                switch (args[0]) {
                    .object => |from_object| switch (from_object.kind) {
                        .array => {
                            switch (args[1]) {
                                .object => |to_object| switch (to_object.kind) {
                                    .array => {
                                        self.runtime.moveArrayState(
                                            @as(*collections.ArrayState, @ptrCast(@alignCast(from_object.ptr))),
                                            @as(*collections.ArrayState, @ptrCast(@alignCast(to_object.ptr))),
                                        );
                                        return .{ .none = {} };
                                    },
                                    else => return error.InvalidExpression,
                                },
                                else => return error.InvalidExpression,
                            }
                        },
                        .map => {
                            switch (args[1]) {
                                .object => |to_object| switch (to_object.kind) {
                                    .map => {
                                        self.runtime.moveMapState(
                                            @as(*collections.MapState, @ptrCast(@alignCast(from_object.ptr))),
                                            @as(*collections.MapState, @ptrCast(@alignCast(to_object.ptr))),
                                        );
                                        return .{ .none = {} };
                                    },
                                    else => return error.InvalidExpression,
                                },
                                else => return error.InvalidExpression,
                            }
                        },
                        else => return error.InvalidExpression,
                    },
                    else => return error.InvalidExpression,
                }
            }
            return .{ .none = {} };
        }
        if (std.ascii.eqlIgnoreCase(name, "reshape")) {
            if (args.len >= 2) {
                const source_state = Runtime.arrayStateFromValue(args[0]) orelse return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                if (!source_state.allocated) return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                var total: i64 = 0;
                switch (args[1]) {
                    .object => |object| switch (object.kind) {
                        .array => {
                            const shape_state = @as(*collections.ArrayState, @ptrCast(@alignCast(object.ptr)));
                            if (!shape_state.allocated) return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                            total = 1;
                            for (shape_state.items.items) |dim| {
                                const n = if (self.strictMode()) try self.strictNumericValue(dim) else toInt(dim);
                                total *= @max(n, 0);
                            }
                        },
                        else => total = if (self.strictMode()) try self.strictNumericValue(args[1]) else toInt(args[1]),
                    },
                    else => total = if (self.strictMode()) try self.strictNumericValue(args[1]) else toInt(args[1]),
                }
                if (total < 0) total = 0;
                const target_len = @as(usize, @intCast(total));
                var items: std.ArrayList(value.Value) = .empty;
                defer items.deinit(self.tmpAllocator());
                var i: usize = 0;
                while (i < target_len) : (i += 1) {
                    const item: value.Value = if (i < source_state.items.items.len) source_state.items.items[i] else if (args.len >= 3) args[2] else .{ .none = {} };
                    try items.append(self.tmpAllocator(), item);
                }
                return try self.runtime.createArrayValue(self.tmpAllocator(), 1, items.items);
            }
            return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
        }
        if (std.ascii.eqlIgnoreCase(name, "pack")) {
            if (args.len >= 2) {
                const source_state = Runtime.arrayStateFromValue(args[0]) orelse return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                const mask_state = Runtime.arrayStateFromValue(args[1]) orelse return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                if (!source_state.allocated or !mask_state.allocated) return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                var items: std.ArrayList(value.Value) = .empty;
                defer items.deinit(self.tmpAllocator());
                const limit = @min(source_state.items.items.len, mask_state.items.items.len);
                var i: usize = 0;
                while (i < limit) : (i += 1) {
                    const mask_value = mask_state.items.items[i];
                    const keep = if (self.strictMode()) try self.boolValue(mask_value) else toBool(mask_value);
                    if (keep) try items.append(self.tmpAllocator(), source_state.items.items[i]);
                }
                return try self.runtime.createArrayValue(self.tmpAllocator(), 1, items.items);
            }
            return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
        }
        if (std.ascii.eqlIgnoreCase(name, "unpack")) {
            if (args.len >= 3) {
                const vector_state = Runtime.arrayStateFromValue(args[0]) orelse return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                const mask_state = Runtime.arrayStateFromValue(args[1]) orelse return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                const field_state = Runtime.arrayStateFromValue(args[2]) orelse return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                if (!vector_state.allocated or !mask_state.allocated or !field_state.allocated) return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
                var items: std.ArrayList(value.Value) = .empty;
                defer items.deinit(self.tmpAllocator());
                const limit = @min(mask_state.items.items.len, field_state.items.items.len);
                var vector_index: usize = 0;
                var i: usize = 0;
                while (i < limit) : (i += 1) {
                    const mask_value = mask_state.items.items[i];
                    const keep = if (self.strictMode()) try self.boolValue(mask_value) else toBool(mask_value);
                    if (keep and vector_index < vector_state.items.items.len) {
                        try items.append(self.tmpAllocator(), vector_state.items.items[vector_index]);
                        vector_index += 1;
                    } else {
                        try items.append(self.tmpAllocator(), field_state.items.items[i]);
                    }
                }
                return try self.runtime.createArrayValue(self.tmpAllocator(), 1, items.items);
            }
            return try self.runtime.createArrayValue(self.tmpAllocator(), 1, &[_]value.Value{});
        }
        if (std.ascii.eqlIgnoreCase(name, "substring")) {
            if (args.len >= 2) {
                const input = try self.valueText(args[0]);
                const start = toInt(args[1]);
                const length = if (args.len >= 3) toInt(args[2]) else null;
                return .{ .string = try self.substringValue(input, start, length) };
            }
            return .{ .string = "" };
        }
        if (std.ascii.eqlIgnoreCase(name, "replace")) {
            if (args.len >= 3) {
                return .{ .string = try self.replaceValue(try self.valueText(args[0]), try self.valueText(args[1]), try self.valueText(args[2])) };
            }
            return .{ .string = "" };
        }
        if (std.ascii.eqlIgnoreCase(name, "translate")) {
            if (args.len >= 3) {
                return .{ .string = try self.translateValue(try self.valueText(args[0]), try self.valueText(args[1]), try self.valueText(args[2])) };
            }
            return .{ .string = "" };
        }
        if (std.ascii.eqlIgnoreCase(name, "strpos")) {
            if (args.len >= 2) {
                return .{ .integer = self.strposValue(try self.valueText(args[0]), try self.valueText(args[1])) };
            }
            return .{ .integer = -1 };
        }
        if (std.ascii.eqlIgnoreCase(name, "lc")) {
            if (args.len >= 1) return .{ .string = try self.lowerValue(try self.valueText(args[0])) };
            return .{ .string = "" };
        }
        if (std.ascii.eqlIgnoreCase(name, "uc")) {
            if (args.len >= 1) return .{ .string = try self.upperValue(try self.valueText(args[0])) };
            return .{ .string = "" };
        }
        if (std.ascii.eqlIgnoreCase(name, "length")) {
            if (args.len >= 1) return .{ .integer = @intCast((try self.valueText(args[0])).len) };
            return .{ .integer = 0 };
        }
        if (std.ascii.eqlIgnoreCase(name, "q")) {
            if (args.len >= 1) return .{ .string = try self.lookupRequestField(self.runtime.context.request.query_string, try self.valueText(args[0])) };
            return .{ .string = "" };
        }
        if (std.ascii.eqlIgnoreCase(name, "f")) {
            if (args.len >= 1) return .{ .string = try self.lookupRequestField(self.runtime.context.request.body, try self.valueText(args[0])) };
            return .{ .string = "" };
        }
        if (std.ascii.eqlIgnoreCase(name, "getcookie")) {
            if (args.len >= 1) return .{ .string = try self.lookupCookie(try self.valueText(args[0])) };
            return .{ .string = "" };
        }
        if (std.ascii.eqlIgnoreCase(name, "script")) {
            return .{ .string = self.currentScriptName() };
        }
        if (std.ascii.eqlIgnoreCase(name, "int")) {
            if (args.len >= 1) return .{ .integer = toInt(args[0]) };
            return .{ .integer = 0 };
        }
        if (std.ascii.eqlIgnoreCase(name, "string")) {
            if (args.len >= 1) return .{ .string = try self.valueText(args[0]) };
            return .{ .string = "" };
        }
        if (std.ascii.eqlIgnoreCase(name, "float")) {
            if (args.len >= 2) {
                const num = toFloat(args[0]);
                const prec = @as(usize, @intCast(@max(@as(i64, 0), toInt(args[1]))));
                return .{ .string = try self.formatFloat(num, prec) };
            }
            if (args.len >= 1) return .{ .float = toFloat(args[0]) };
            return .{ .float = 0 };
        }
        if (std.ascii.eqlIgnoreCase(name, "format")) {
            if (args.len >= 1) {
                const num = toFloat(args[0]);
                const prec = if (args.len >= 2) @as(usize, @intCast(@max(@as(i64, 0), toInt(args[1])))) else 0;
                return .{ .string = try self.formatFloat(num, prec) };
            }
            return .{ .string = "" };
        }
        if (std.ascii.eqlIgnoreCase(name, "urldecode")) {
            if (args.len >= 1) return .{ .string = try self.urlDecode(try self.valueText(args[0])) };
            return .{ .string = "" };
        }
        if (std.ascii.eqlIgnoreCase(name, "fileexists")) {
            if (args.len >= 1) return .{ .boolean = self.fileExists(try self.valueText(args[0])) };
            return .{ .boolean = false };
        }
        if (std.ascii.eqlIgnoreCase(name, "filesize")) {
            if (args.len >= 1) return .{ .integer = self.fileSize(try self.valueText(args[0])) };
            return .{ .integer = -1 };
        }
        if (std.ascii.eqlIgnoreCase(name, "len")) {
            if (args.len >= 1) return .{ .integer = @intCast((try self.valueText(args[0])).len) };
            return .{ .integer = 0 };
        }
        if (std.ascii.eqlIgnoreCase(name, "include")) {
            if (args.len >= 1) try self.includePath(try self.valueText(args[0]), writer);
            return .{ .none = {} };
        }

        if (self.runtime.getFunction(name)) |def| {
            return try self.callUserFunction(def, args, writer);
        }

        return .{ .none = {} };
    }

    fn callUserFunction(self: *Runner, def: *FunctionDef, args: []value.Value, writer: anytype) anyerror!value.Value {
        const scope_mark = self.runtime.variables.items.len;
        errdefer self.popScopeTo(scope_mark);

        for (def.params, 0..) |param, index| {
            const arg: value.Value = if (index < args.len) args[index] else .{ .none = {} };
            try self.runtime.variables.append(self.runtime.allocator, .{
                .name = try self.runtime.allocator.dupe(u8, param),
                .value = try self.runtime.cloneValue(arg),
            });
        }

        var nested = try Runner.init(self.runtime, def.body_source, def.current_path);
        defer nested.deinit();
        const flow = try nested.runBlockChunk(writer);

        self.popScopeTo(scope_mark);

        switch (flow) {
            .normal => return .{ .none = {} },
            .exit => return .{ .none = {} },
            .return_value => |ret| return try self.runtime.cloneValueToAllocator(self.tmpAllocator(), ret),
        }
    }

    fn popScopeTo(self: *Runner, mark: usize) void {
        while (self.runtime.variables.items.len > mark) {
            const binding = self.runtime.variables.pop().?;
            self.runtime.freeValue(binding.value);
            self.runtime.allocator.free(binding.name);
        }
    }

    fn lookupRequestField(self: *Runner, source: []const u8, key: []const u8) ![]const u8 {
        _ = self;
        var start: usize = 0;
        while (start <= source.len) {
            var end = start;
            while (end < source.len and source[end] != '&' and source[end] != ';') : (end += 1) {}
            const pair = std.mem.trim(u8, source[start..end], " \t\r\n");
            if (pair.len != 0) {
                const eq = std.mem.indexOfScalar(u8, pair, '=') orelse pair.len;
                const name = std.mem.trim(u8, pair[0..eq], " \t\r\n");
                const value_slice = if (eq < pair.len) pair[eq + 1 ..] else "";
                if (std.ascii.eqlIgnoreCase(name, key)) {
                    return value_slice;
                }
            }
            if (end >= source.len) break;
            start = end + 1;
        }
        return "";
    }

    fn lookupCookie(self: *Runner, key: []const u8) ![]const u8 {
        return self.lookupRequestField(self.runtime.context.request.cookie_header, key);
    }

    fn includePath(self: *Runner, include_path: []const u8, writer: anytype) anyerror!void {
        const resolved = try self.resolveIncludePath(include_path);
        defer self.runtime.allocator.free(resolved);
        const source = try std.Io.Dir.cwd().readFileAlloc(self.runtime.io, resolved, self.runtime.allocator, .limited(max_source_bytes));
        defer self.runtime.allocator.free(source);
        try self.runtime.runSourceAtPath(source, writer, resolved);
    }

    fn resolveIncludePath(self: *Runner, include_path: []const u8) ![]u8 {
        if (include_path.len == 0) return self.runtime.allocator.dupe(u8, include_path);
        if (std.fs.path.isAbsolute(include_path)) return self.runtime.allocator.dupe(u8, include_path);
        const base_dir = std.fs.path.dirname(self.current_path) orelse "";
        if (base_dir.len == 0) return self.runtime.allocator.dupe(u8, include_path);
        return std.fs.path.join(self.runtime.allocator, &.{ base_dir, include_path });
    }

    fn urlDecode(self: *Runner, input: []const u8) ![]u8 {
        const buffer = try self.tmpAllocator().dupe(u8, input);
        for (buffer) |*c| {
            if (c.* == '+') c.* = ' ';
        }
        return std.Uri.percentDecodeInPlace(buffer);
    }

    fn formatFloat(self: *Runner, value_in: f64, precision: usize) ![]u8 {
        var buf: [128]u8 = undefined;
        const slice = try std.fmt.float.render(&buf, value_in, .{
            .mode = .decimal,
            .precision = precision,
        });
        return self.tmpAllocator().dupe(u8, slice);
    }

    fn dateSeconds(self: *Runner, v: value.Value) !i64 {
        _ = self;
        return switch (v) {
            .none => 0,
            .boolean => |b| if (b) 1 else 0,
            .integer => |i| i,
            .float => |f| @as(i64, @intFromFloat(f)),
            .string => |s| try date.parseText(s, Runtime.currentUnixSeconds()),
            .cookie => |cookie| try date.parseText(cookie.value, Runtime.currentUnixSeconds()),
            .object => 0,
        };
    }

    fn dateFromYmd(self: *Runner, year_value: value.Value, month_value: value.Value, day_value: value.Value) !i64 {
        const year = try self.strictNumericValue(year_value);
        const month = try self.strictNumericValue(month_value);
        const day = try self.strictNumericValue(day_value);
        return try date.encodeDateTime(@as(i32, @intCast(year)), month, day, 0, 0, 0);
    }

    fn fileExists(self: *Runner, path: []const u8) bool {
        const cwd = std.Io.Dir.cwd();
        const file = cwd.openFile(self.runtime.io, path, .{
            .mode = .read_only,
            .allow_directory = false,
        }) catch return false;
        defer file.close(self.runtime.io);
        return true;
    }

    fn fileSize(self: *Runner, path: []const u8) i64 {
        const cwd = std.Io.Dir.cwd();
        const file = cwd.openFile(self.runtime.io, path, .{
            .mode = .read_only,
            .allow_directory = false,
        }) catch return -1;
        defer file.close(self.runtime.io);

        const st = file.stat(self.runtime.io) catch return -1;
        if (st.kind != .file) return -1;
        if (st.size > @as(u64, @intCast(std.math.maxInt(i64)))) return -1;
        return @as(i64, @intCast(st.size));
    }

    fn matchOperator(self: *const Runner, kind: TokenKind) bool {
        const token = self.peek(0) orelse return false;
        return token.kind == kind;
    }

    fn consumeOperator(self: *Runner, kind: TokenKind) !void {
        if (!self.matchOperator(kind)) return error.InvalidExpression;
        self.pos += 1;
    }

    fn parseCommaSeparatedParams(self: *Runner) ![][]u8 {
        var params = std.ArrayList([]u8).empty;
        errdefer params.deinit(self.runtime.allocator);

        if (!self.matchOperator(.r_paren)) {
            while (true) {
                const param_name = try self.consumeIdentifier();
                try params.append(self.runtime.allocator, try canonicalName(self.runtime.allocator, param_name));
                self.skipEols();
                if (self.matchOperator(.comma)) {
                    self.pos += 1;
                    self.skipEols();
                    continue;
                }
                break;
            }
        }
        return try params.toOwnedSlice(self.runtime.allocator);
    }

    fn parseFunctionBodySource(self: *Runner, body_start: usize) []const u8 {
        const body_end = self.positionSource();
        return self.source[body_start..body_end];
    }

    fn tokenize(allocator: std.mem.Allocator, source: []const u8, tokens: *std.ArrayList(Token)) !void {
        var i: usize = 0;
        while (i < source.len) {
            const c = source[i];
            switch (c) {
                ' ', '\t', '\x0b', '\x0c' => i += 1,
                '\r' => {
                    i += 1;
                    if (i < source.len and source[i] == '\n') i += 1;
                    try tokens.append(allocator, .{ .kind = .eol, .start = i, .end = i });
                },
                '\n' => {
                    i += 1;
                    try tokens.append(allocator, .{ .kind = .eol, .start = i, .end = i });
                },
                '\'' => {
                    while (i < source.len and source[i] != '\n' and source[i] != '\r') : (i += 1) {}
                },
                ':' => {
                    i += 1;
                    try tokens.append(allocator, .{ .kind = .eol, .start = i, .end = i });
                },
                ';' => {
                    i += 1;
                    try tokens.append(allocator, .{ .kind = .eol, .start = i, .end = i });
                },
                '(' => {
                    try tokens.append(allocator, .{ .kind = .l_paren, .start = i, .end = i + 1 });
                    i += 1;
                },
                ')' => {
                    try tokens.append(allocator, .{ .kind = .r_paren, .start = i, .end = i + 1 });
                    i += 1;
                },
                '[' => {
                    try tokens.append(allocator, .{ .kind = .l_bracket, .start = i, .end = i + 1 });
                    i += 1;
                },
                ']' => {
                    try tokens.append(allocator, .{ .kind = .r_bracket, .start = i, .end = i + 1 });
                    i += 1;
                },
                ',' => {
                    try tokens.append(allocator, .{ .kind = .comma, .start = i, .end = i + 1 });
                    i += 1;
                },
                '.' => {
                    try tokens.append(allocator, .{ .kind = .dot, .start = i, .end = i + 1 });
                    i += 1;
                },
                '+' => {
                    try tokens.append(allocator, .{ .kind = .plus, .start = i, .end = i + 1 });
                    i += 1;
                },
                '-' => {
                    try tokens.append(allocator, .{ .kind = .minus, .start = i, .end = i + 1 });
                    i += 1;
                },
                '*' => {
                    try tokens.append(allocator, .{ .kind = .star, .start = i, .end = i + 1 });
                    i += 1;
                },
                '/' => {
                    try tokens.append(allocator, .{ .kind = .slash, .start = i, .end = i + 1 });
                    i += 1;
                },
                '&' => {
                    try tokens.append(allocator, .{ .kind = .amp, .start = i, .end = i + 1 });
                    i += 1;
                },
                '=' => {
                    try tokens.append(allocator, .{ .kind = .eq, .start = i, .end = i + 1 });
                    i += 1;
                },
                '<' => {
                    if (i + 1 < source.len) {
                        switch (source[i + 1]) {
                            '=' => {
                                try tokens.append(allocator, .{ .kind = .lte, .start = i, .end = i + 2 });
                                i += 2;
                            },
                            '>' => {
                                try tokens.append(allocator, .{ .kind = .neq, .start = i, .end = i + 2 });
                                i += 2;
                            },
                            else => {
                                try tokens.append(allocator, .{ .kind = .lt, .start = i, .end = i + 1 });
                                i += 1;
                            },
                        }
                    } else {
                        try tokens.append(allocator, .{ .kind = .lt, .start = i, .end = i + 1 });
                        i += 1;
                    }
                },
                '>' => {
                    if (i + 1 < source.len and source[i + 1] == '=') {
                        try tokens.append(allocator, .{ .kind = .gte, .start = i, .end = i + 2 });
                        i += 2;
                    } else {
                        try tokens.append(allocator, .{ .kind = .gt, .start = i, .end = i + 1 });
                        i += 1;
                    }
                },
                '"' => {
                    const start = i;
                    i += 1;
                    while (i < source.len) {
                        if (source[i] == '\\' and i + 1 < source.len) {
                            i += 2;
                            continue;
                        }
                        if (source[i] == '"') {
                            if (i + 1 < source.len and source[i + 1] == '"') {
                                i += 2;
                                continue;
                            }
                            i += 1;
                            break;
                        }
                        i += 1;
                    }
                    try tokens.append(allocator, .{ .kind = .string, .start = start, .end = i });
                },
                '0'...'9' => {
                    const start = i;
                    i += 1;
                    var saw_dot = false;
                    while (i < source.len) {
                        const ch = source[i];
                        if (ch >= '0' and ch <= '9') {
                            i += 1;
                            continue;
                        }
                        if (!saw_dot and ch == '.' and i + 1 < source.len and source[i + 1] >= '0' and source[i + 1] <= '9') {
                            saw_dot = true;
                            i += 1;
                            continue;
                        }
                        break;
                    }
                    try tokens.append(allocator, .{ .kind = .number, .start = start, .end = i });
                },
                else => {
                    if (std.ascii.isAlphabetic(c) or c == '_') {
                        const start = i;
                        i += 1;
                        while (i < source.len) {
                            const ch = source[i];
                            if (std.ascii.isAlphanumeric(ch) or ch == '_' or ch == '$') {
                                i += 1;
                                continue;
                            }
                            break;
                        }
                        try tokens.append(allocator, .{ .kind = .identifier, .start = start, .end = i });
                    } else {
                        i += 1;
                    }
                },
            }
        }

        try tokens.append(allocator, .{ .kind = .eof, .start = source.len, .end = source.len });
    }

    fn applyBinary(self: *Runner, op: BinaryOperator, lhs: value.Value, rhs: value.Value, execute: bool) !value.Value {
        const strict = execute and self.strictMode();
        return switch (op.op) {
            .plus => .{ .integer = if (strict) try self.strictNumericValue(lhs) + try self.strictNumericValue(rhs) else toInt(lhs) + toInt(rhs) },
            .minus => .{ .integer = if (strict) try self.strictNumericValue(lhs) - try self.strictNumericValue(rhs) else toInt(lhs) - toInt(rhs) },
            .star => .{ .integer = if (strict) try self.strictNumericValue(lhs) * try self.strictNumericValue(rhs) else toInt(lhs) * toInt(rhs) },
            .slash => .{ .float = if (strict) blk: {
                const rhs_num = try self.strictFloatValue(rhs);
                if (rhs_num == 0) break :blk 0;
                break :blk try self.strictFloatValue(lhs) / rhs_num;
            } else if (toFloatStatic(rhs) == 0) 0 else toFloatStatic(lhs) / toFloatStatic(rhs) },
            .amp => .{ .string = try self.concatValues(lhs, rhs, strict) },
            .eq => .{ .boolean = try self.compareValues(lhs, rhs, strict) == .eq },
            .lt => .{ .boolean = try self.compareValues(lhs, rhs, strict) == .lt },
            .gt => .{ .boolean = try self.compareValues(lhs, rhs, strict) == .gt },
            .lte => .{ .boolean = try self.compareValues(lhs, rhs, strict) != .gt },
            .gte => .{ .boolean = try self.compareValues(lhs, rhs, strict) != .lt },
            .neq => .{ .boolean = try self.compareValues(lhs, rhs, strict) != .eq },
            .identifier => blk: {
                if (op.keyword) |keyword| {
                    if (std.ascii.eqlIgnoreCase(keyword, "and")) {
                        const left = if (strict) try self.boolValue(lhs) else toBool(lhs);
                        const right = if (strict) try self.boolValue(rhs) else toBool(rhs);
                        break :blk .{ .boolean = left and right };
                    }
                    if (std.ascii.eqlIgnoreCase(keyword, "or")) {
                        const left = if (strict) try self.boolValue(lhs) else toBool(lhs);
                        const right = if (strict) try self.boolValue(rhs) else toBool(rhs);
                        break :blk .{ .boolean = left or right };
                    }
                }
                break :blk .{ .none = {} };
            },
            else => .{ .none = {} },
        };
    }

    fn concatValues(self: *Runner, lhs: value.Value, rhs: value.Value, strict: bool) ![]u8 {
        const left = if (strict) try self.strictStringValue(lhs) else try self.valueText(lhs);
        const right = if (strict) try self.strictStringValue(rhs) else try self.valueText(rhs);
        const joined = try self.tmpAllocator().alloc(u8, left.len + right.len);
        @memcpy(joined[0..left.len], left);
        @memcpy(joined[left.len..][0..right.len], right);
        return joined;
    }

    fn decodeString(self: *Runner, token: Token) ![]u8 {
        const raw = self.text(token);
        if (raw.len < 2) return self.tmpAllocator().dupe(u8, "");
        const copy = try self.tmpAllocator().dupe(u8, raw[1 .. raw.len - 1]);
        return std.Uri.percentDecodeInPlace(copy);
    }
};

fn canonicalName(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    const copy = try allocator.dupe(u8, text);
    _ = std.ascii.lowerString(copy, copy);
    return copy;
}

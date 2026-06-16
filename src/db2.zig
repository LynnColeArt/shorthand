const std = @import("std");
const dbspec = @import("dbspec.zig");
const value = @import("value.zig");

const legacy_dump = @embedFile("data/smoses_secondary.sql");

pub const ConnectionStatus = dbspec.ConnectionStatus;

pub const ConnectionState = struct {
    db: LegacyDatabase = .{},
    spec: dbspec.ConnectionSpec = .{},
    opened_at: i64 = 0,
    last_used_at: i64 = 0,
    last_refresh_at: i64 = 0,
    generation: u64 = 0,
    refresh_count: u64 = 0,

    fn markOpened(self: *ConnectionState, now: i64) void {
        self.opened_at = now;
        self.last_used_at = now;
        self.last_refresh_at = now;
    }

    fn touch(self: *ConnectionState, now: i64) void {
        self.last_used_at = now;
    }

    fn elapsedSeconds(now: i64, earlier: i64) u64 {
        if (now <= earlier) return 0;
        return @as(u64, @intCast(now - earlier));
    }

    fn isStale(self: *const ConnectionState, now: i64) bool {
        if (self.opened_at == 0 or self.last_used_at == 0) return false;

        if (self.spec.policy.idle_timeout_seconds) |idle_timeout| {
            if (elapsedSeconds(now, self.last_used_at) >= idle_timeout) return true;
        }

        if (self.spec.policy.max_age_seconds) |max_age| {
            if (elapsedSeconds(now, self.opened_at) >= max_age) return true;
        }

        return false;
    }

    fn refresh(self: *ConnectionState, now: i64) void {
        self.generation += 1;
        self.refresh_count += 1;
        self.last_refresh_at = now;
        self.touch(now);
    }

    fn ensureFresh(self: *ConnectionState, allocator: std.mem.Allocator) anyerror!void {
        const now = dbspec.currentUnixSeconds();
        if (self.opened_at == 0 or self.last_used_at == 0 or self.last_refresh_at == 0) {
            self.markOpened(now);
            return;
        }
        if (self.spec.policy.auto_refresh and self.isStale(now)) {
            self.refresh(now);
        } else {
            self.touch(now);
        }
        _ = allocator;
    }

    pub fn deinit(self: *ConnectionState, allocator: std.mem.Allocator) void {
        self.db.deinit(allocator);
        self.spec.deinit(allocator);
    }
};

const Configuration = struct {
    autoid: i64,
    primary_color: []u8,
    secondary_color: []u8,
    code_thumbnail: []u8,
    thumbnails: i64,
    allow_subs: i64,
    reviews: i64,
    alsobought: i64,
    currency: []u8,
    title: []u8,
    desc_length: i64,
};

const Category = struct {
    category_id: i64,
    category_name: []u8,
};

const Product = struct {
    product_id: i64,
    category_id: i64,
    model_number: []u8,
    model_name: []u8,
    product_image: []u8,
    product_status: i64,
    product_stock: i64,
    unit_cost: []u8,
    description: []u8,
};

const OrderDetail = struct {
    autoid: i64,
    orderstate: i64,
    order_id: []u8,
    product_id: i64,
    quantity: i64,
};

pub const LegacyDatabase = struct {
    categories: std.ArrayList(Category) = .empty,
    configuration: ?Configuration = null,
    products: std.ArrayList(Product) = .empty,
    orderdetails: std.ArrayList(OrderDetail) = .empty,
    next_orderdetail_id: i64 = 1,

    pub fn deinit(self: *LegacyDatabase, allocator: std.mem.Allocator) void {
        for (self.categories.items) |category| {
            allocator.free(category.category_name);
        }
        self.categories.deinit(allocator);

        if (self.configuration) |config| {
            allocator.free(config.primary_color);
            allocator.free(config.secondary_color);
            allocator.free(config.code_thumbnail);
            allocator.free(config.currency);
            allocator.free(config.title);
        }

        for (self.products.items) |product| {
            allocator.free(product.model_number);
            allocator.free(product.model_name);
            allocator.free(product.product_image);
            allocator.free(product.unit_cost);
            allocator.free(product.description);
        }
        self.products.deinit(allocator);

        for (self.orderdetails.items) |detail| {
            allocator.free(detail.order_id);
        }
        self.orderdetails.deinit(allocator);
        self.configuration = null;
    }
};

const Field = struct {
    name: []u8,
    value: value.Value,
};

const Row = struct {
    fields: []Field,
};

pub const RecordsetState = struct {
    connection: *ConnectionState,
    sql: []u8,
    rows: std.ArrayList(Row) = .empty,
    position: isize = -1,
};

pub const DdlState = struct {
    connection: *ConnectionState,
    sql: []u8,
};

fn startsWithIgnoreCase(text: []const u8, prefix: []const u8) bool {
    return text.len >= prefix.len and std.ascii.eqlIgnoreCase(text[0..prefix.len], prefix);
}

fn containsIgnoreCase(text: []const u8, needle: []const u8) bool {
    return std.ascii.indexOfIgnoreCase(text, needle) != null;
}

fn parseIntValue(v: value.Value) i64 {
    return switch (v) {
        .none => 0,
        .boolean => |b| if (b) 1 else 0,
        .integer => |i| i,
        .float => |f| @as(i64, @intFromFloat(f)),
        .string => |s| std.fmt.parseInt(i64, s, 10) catch blk: {
            const parsed = std.fmt.parseFloat(f64, s) catch break :blk 0;
            break :blk @as(i64, @intFromFloat(parsed));
        },
        .cookie => |c| std.fmt.parseInt(i64, c.value, 10) catch blk: {
            const parsed = std.fmt.parseFloat(f64, c.value) catch break :blk 0;
            break :blk @as(i64, @intFromFloat(parsed));
        },
        .object => 0,
    };
}

fn parseFloatValue(v: value.Value) f64 {
    return switch (v) {
        .none => 0,
        .boolean => |b| if (b) 1 else 0,
        .integer => |i| @as(f64, @floatFromInt(i)),
        .float => |f| f,
        .string => |s| std.fmt.parseFloat(f64, s) catch 0,
        .cookie => |c| std.fmt.parseFloat(f64, c.value) catch 0,
        .object => 0,
    };
}

fn cloneValue(allocator: std.mem.Allocator, v: value.Value) !value.Value {
    return switch (v) {
        .none => .{ .none = {} },
        .boolean => |b| .{ .boolean = b },
        .integer => |i| .{ .integer = i },
        .float => |f| .{ .float = f },
        .string => |s| .{ .string = try allocator.dupe(u8, s) },
        .cookie => |c| .{ .cookie = c },
        .object => .{ .object = v.object },
    };
}

fn freeValue(allocator: std.mem.Allocator, v: value.Value) void {
    switch (v) {
        .string => |s| allocator.free(s),
        .cookie => |c| {
            allocator.free(c.name);
            allocator.free(c.value);
            if (c.path) |path| allocator.free(path);
            if (c.domain) |domain| allocator.free(domain);
            if (c.expires) |expires| allocator.free(expires);
        },
        else => {},
    }
}

fn textFromValue(allocator: std.mem.Allocator, v: value.Value) ![]u8 {
    return switch (v) {
        .none => try allocator.dupe(u8, ""),
        .boolean => |b| try allocator.dupe(u8, if (b) "true" else "false"),
        .integer => |i| try std.fmt.allocPrint(allocator, "{d}", .{i}),
        .float => |f| try std.fmt.allocPrint(allocator, "{d}", .{f}),
        .string => |s| try allocator.dupe(u8, s),
        .cookie => |c| try allocator.dupe(u8, c.value),
        .object => try allocator.dupe(u8, ""),
    };
}

fn addField(allocator: std.mem.Allocator, fields: *std.ArrayList(Field), name: []const u8, v: value.Value) !void {
    try fields.append(allocator, .{
        .name = try allocator.dupe(u8, name),
        .value = try cloneValue(allocator, v),
    });
}

fn freeParsedValues(allocator: std.mem.Allocator, parsed: []value.Value) void {
    for (parsed) |item| freeValue(allocator, item);
}

fn parseQuotedString(allocator: std.mem.Allocator, input: []const u8, i: *usize) ![]u8 {
    if (input[i.*] != '\'') return error.InvalidData;
    i.* += 1;

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    while (i.* < input.len) {
        const c = input[i.*];
        if (c == '\\' and i.* + 1 < input.len) {
            try out.append(allocator, input[i.* + 1]);
            i.* += 2;
            continue;
        }
        if (c == '\'') {
            if (i.* + 1 < input.len and input[i.* + 1] == '\'') {
                try out.append(allocator, '\'');
                i.* += 2;
                continue;
            }
            i.* += 1;
            break;
        }
        try out.append(allocator, c);
        i.* += 1;
    }

    return try out.toOwnedSlice(allocator);
}

fn parseInsertValues(allocator: std.mem.Allocator, line: []const u8) ![]value.Value {
    const values_index = std.ascii.indexOfIgnoreCase(line, "values") orelse return error.InvalidData;
    const open_index = std.mem.indexOfScalarPos(u8, line, values_index, '(') orelse return error.InvalidData;
    const close_index = std.mem.lastIndexOfScalar(u8, line, ')') orelse return error.InvalidData;
    const slice = line[open_index + 1 .. close_index];

    var parsed: std.ArrayList(value.Value) = .empty;
    errdefer {
        freeParsedValues(allocator, parsed.items);
        parsed.deinit(allocator);
    }

    var i: usize = 0;
    while (i < slice.len) {
        while (i < slice.len and (slice[i] == ' ' or slice[i] == '\t' or slice[i] == ',')) : (i += 1) {}
        if (i >= slice.len) break;

        if (slice[i] == '\'') {
            const str = try parseQuotedString(allocator, slice, &i);
            try parsed.append(allocator, .{ .string = str });
        } else {
            const start = i;
            while (i < slice.len and slice[i] != ',') : (i += 1) {}
            const token = std.mem.trim(u8, slice[start..i], " \t\r");
            if (token.len == 0 or std.ascii.eqlIgnoreCase(token, "null")) {
                try parsed.append(allocator, .{ .none = {} });
            } else if (std.mem.indexOfScalar(u8, token, '.') != null) {
                try parsed.append(allocator, .{ .float = std.fmt.parseFloat(f64, token) catch 0 });
            } else {
                try parsed.append(allocator, .{ .integer = std.fmt.parseInt(i64, token, 10) catch 0 });
            }
        }

        if (i < slice.len and slice[i] == ',') i += 1;
    }

    return try parsed.toOwnedSlice(allocator);
}

fn insertConfiguration(db: *LegacyDatabase, allocator: std.mem.Allocator, values: []value.Value) !void {
    if (values.len < 11) return error.InvalidData;
    const config = Configuration{
        .autoid = parseIntValue(values[0]),
        .primary_color = try textFromValue(allocator, values[1]),
        .secondary_color = try textFromValue(allocator, values[2]),
        .code_thumbnail = try textFromValue(allocator, values[3]),
        .thumbnails = parseIntValue(values[4]),
        .allow_subs = parseIntValue(values[5]),
        .reviews = parseIntValue(values[6]),
        .alsobought = parseIntValue(values[7]),
        .currency = try textFromValue(allocator, values[8]),
        .title = try textFromValue(allocator, values[9]),
        .desc_length = parseIntValue(values[10]),
    };
    if (db.configuration) |existing| {
        allocator.free(existing.primary_color);
        allocator.free(existing.secondary_color);
        allocator.free(existing.code_thumbnail);
        allocator.free(existing.currency);
        allocator.free(existing.title);
    }
    db.configuration = config;
}

fn insertCategory(db: *LegacyDatabase, allocator: std.mem.Allocator, values: []value.Value) !void {
    if (values.len < 2) return error.InvalidData;
    try db.categories.append(allocator, .{
        .category_id = parseIntValue(values[0]),
        .category_name = try textFromValue(allocator, values[1]),
    });
}

fn insertProduct(db: *LegacyDatabase, allocator: std.mem.Allocator, values: []value.Value) !void {
    if (values.len < 9) return error.InvalidData;
    try db.products.append(allocator, .{
        .product_id = parseIntValue(values[0]),
        .category_id = parseIntValue(values[1]),
        .model_number = try textFromValue(allocator, values[2]),
        .model_name = try textFromValue(allocator, values[3]),
        .product_image = try textFromValue(allocator, values[4]),
        .product_status = parseIntValue(values[5]),
        .product_stock = parseIntValue(values[6]),
        .unit_cost = try textFromValue(allocator, values[7]),
        .description = try textFromValue(allocator, values[8]),
    });
}

fn insertOrderDetail(db: *LegacyDatabase, allocator: std.mem.Allocator, values: []value.Value) !void {
    if (values.len < 5) return error.InvalidData;
    const autoid = parseIntValue(values[0]);
    try db.orderdetails.append(allocator, .{
        .autoid = autoid,
        .orderstate = parseIntValue(values[1]),
        .order_id = try textFromValue(allocator, values[2]),
        .product_id = parseIntValue(values[3]),
        .quantity = parseIntValue(values[4]),
    });
    if (autoid >= db.next_orderdetail_id) {
        db.next_orderdetail_id = autoid + 1;
    }
}

fn loadFromDump(db: *LegacyDatabase, allocator: std.mem.Allocator) anyerror!void {
    var lines = std.mem.splitScalar(u8, legacy_dump, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0) continue;
        if (!startsWithIgnoreCase(trimmed, "INSERT INTO")) continue;

        const is_configuration = containsIgnoreCase(trimmed, "cart_configuration");
        const is_categories = containsIgnoreCase(trimmed, "cart_categories");
        const is_products = containsIgnoreCase(trimmed, "cart_products");
        const is_orderdetails = containsIgnoreCase(trimmed, "cart_orderdetails");
        if (!is_configuration and !is_categories and !is_products and !is_orderdetails) continue;

        const values = try parseInsertValues(allocator, trimmed);
        errdefer freeParsedValues(allocator, values);

        if (is_configuration) {
            try insertConfiguration(db, allocator, values);
        } else if (is_categories) {
            try insertCategory(db, allocator, values);
        } else if (is_products) {
            try insertProduct(db, allocator, values);
        } else if (is_orderdetails) {
            try insertOrderDetail(db, allocator, values);
        }

        freeParsedValues(allocator, values);
        allocator.free(values);
    }
}

pub fn createConnection(allocator: std.mem.Allocator, driver: []const u8, connection_string: []const u8) anyerror!value.ObjectValue {
    const state = try allocator.create(ConnectionState);
    errdefer allocator.destroy(state);
    state.* = .{
        .spec = try dbspec.createConnectionSpec(allocator, driver, connection_string),
    };
    errdefer state.deinit(allocator);
    try loadFromDump(&state.db, allocator);
    state.markOpened(dbspec.currentUnixSeconds());
    return .{ .kind = .connection, .ptr = state };
}

pub fn createRecordset(allocator: std.mem.Allocator, connection: *ConnectionState, sql: []const u8) anyerror!value.ObjectValue {
    const state = try allocator.create(RecordsetState);
    errdefer allocator.destroy(state);
    state.* = .{
        .connection = connection,
        .sql = try allocator.dupe(u8, sql),
    };
    return .{ .kind = .recordset, .ptr = state };
}

pub fn createDdl(allocator: std.mem.Allocator, connection: *ConnectionState, sql: []const u8) anyerror!value.ObjectValue {
    const state = try allocator.create(DdlState);
    errdefer allocator.destroy(state);
    state.* = .{
        .connection = connection,
        .sql = try allocator.dupe(u8, sql),
    };
    return .{ .kind = .ddl, .ptr = state };
}

pub fn connectionFromValue(v: value.Value) ?*ConnectionState {
    if (v != .object) return null;
    if (v.object.kind != .connection) return null;
    return @as(*ConnectionState, @ptrCast(@alignCast(v.object.ptr)));
}

pub fn recordsetFromValue(v: value.Value) ?*RecordsetState {
    if (v != .object) return null;
    if (v.object.kind != .recordset) return null;
    return @as(*RecordsetState, @ptrCast(@alignCast(v.object.ptr)));
}

pub fn ddlFromValue(v: value.Value) ?*DdlState {
    if (v != .object) return null;
    if (v.object.kind != .ddl) return null;
    return @as(*DdlState, @ptrCast(@alignCast(v.object.ptr)));
}

pub fn connectionStatus(self: *const ConnectionState) ConnectionStatus {
    const now = dbspec.currentUnixSeconds();
    return .{
        .backend = self.spec.backend,
        .driver_name = self.spec.driver_name,
        .connection_string = self.spec.connection_string,
        .opened_at = self.opened_at,
        .last_used_at = self.last_used_at,
        .last_refresh_at = self.last_refresh_at,
        .generation = self.generation,
        .refresh_count = self.refresh_count,
        .policy = self.spec.policy,
        .stale = self.isStale(now),
    };
}

fn clearRows(allocator: std.mem.Allocator, rows: *std.ArrayList(Row)) void {
    for (rows.items) |row| {
        for (row.fields) |field| {
            allocator.free(field.name);
            freeValue(allocator, field.value);
        }
        allocator.free(row.fields);
    }
    rows.clearRetainingCapacity();
}

fn appendConfigRow(allocator: std.mem.Allocator, rows: *std.ArrayList(Row), config: Configuration) !void {
    var fields: std.ArrayList(Field) = .empty;
    errdefer {
        for (fields.items) |field| {
            allocator.free(field.name);
            freeValue(allocator, field.value);
        }
        fields.deinit(allocator);
    }
    try addField(allocator, &fields, "autoid", .{ .integer = config.autoid });
    try addField(allocator, &fields, "primary_color", .{ .string = config.primary_color });
    try addField(allocator, &fields, "secondary_color", .{ .string = config.secondary_color });
    try addField(allocator, &fields, "code_thumbnail", .{ .string = config.code_thumbnail });
    try addField(allocator, &fields, "thumbnails", .{ .integer = config.thumbnails });
    try addField(allocator, &fields, "allow_subs", .{ .integer = config.allow_subs });
    try addField(allocator, &fields, "reviews", .{ .integer = config.reviews });
    try addField(allocator, &fields, "alsobought", .{ .integer = config.alsobought });
    try addField(allocator, &fields, "currency", .{ .string = config.currency });
    try addField(allocator, &fields, "title", .{ .string = config.title });
    try addField(allocator, &fields, "desc_length", .{ .integer = config.desc_length });
    try rows.append(allocator, .{ .fields = try fields.toOwnedSlice(allocator) });
}

fn appendProductRow(allocator: std.mem.Allocator, rows: *std.ArrayList(Row), product: Product) !void {
    var fields: std.ArrayList(Field) = .empty;
    errdefer {
        for (fields.items) |field| {
            allocator.free(field.name);
            freeValue(allocator, field.value);
        }
        fields.deinit(allocator);
    }
    try addField(allocator, &fields, "ProductID", .{ .integer = product.product_id });
    try addField(allocator, &fields, "CategoryID", .{ .integer = product.category_id });
    try addField(allocator, &fields, "ModelNumber", .{ .string = product.model_number });
    try addField(allocator, &fields, "ModelName", .{ .string = product.model_name });
    try addField(allocator, &fields, "ProductImage", .{ .string = product.product_image });
    try addField(allocator, &fields, "ProductStatus", .{ .integer = product.product_status });
    try addField(allocator, &fields, "Productstock", .{ .integer = product.product_stock });
    try addField(allocator, &fields, "UnitCost", .{ .string = product.unit_cost });
    try addField(allocator, &fields, "Description", .{ .string = product.description });
    try rows.append(allocator, .{ .fields = try fields.toOwnedSlice(allocator) });
}

fn appendOrderDetailRow(allocator: std.mem.Allocator, rows: *std.ArrayList(Row), detail: OrderDetail) !void {
    var fields: std.ArrayList(Field) = .empty;
    errdefer {
        for (fields.items) |field| {
            allocator.free(field.name);
            freeValue(allocator, field.value);
        }
        fields.deinit(allocator);
    }
    try addField(allocator, &fields, "autoid", .{ .integer = detail.autoid });
    try addField(allocator, &fields, "orderstate", .{ .integer = detail.orderstate });
    try addField(allocator, &fields, "OrderID", .{ .string = detail.order_id });
    try addField(allocator, &fields, "ProductID", .{ .integer = detail.product_id });
    try addField(allocator, &fields, "Quantity", .{ .integer = detail.quantity });
    try rows.append(allocator, .{ .fields = try fields.toOwnedSlice(allocator) });
}

fn appendJoinRow(allocator: std.mem.Allocator, rows: *std.ArrayList(Row), detail: OrderDetail, product: Product) !void {
    var fields: std.ArrayList(Field) = .empty;
    errdefer {
        for (fields.items) |field| {
            allocator.free(field.name);
            freeValue(allocator, field.value);
        }
        fields.deinit(allocator);
    }
    try addField(allocator, &fields, "autoid", .{ .integer = detail.autoid });
    try addField(allocator, &fields, "orderid", .{ .string = detail.order_id });
    try addField(allocator, &fields, "productid", .{ .integer = detail.product_id });
    try addField(allocator, &fields, "qty", .{ .integer = detail.quantity });
    try addField(allocator, &fields, "modelname", .{ .string = product.model_name });
    try addField(allocator, &fields, "unitcost", .{ .string = product.unit_cost });
    try rows.append(allocator, .{ .fields = try fields.toOwnedSlice(allocator) });
}

fn appendProductSlice(allocator: std.mem.Allocator, rows: *std.ArrayList(Row), slice: []const Product) !void {
    for (slice) |product| try appendProductRow(allocator, rows, product);
}

fn findProductById(db: *const LegacyDatabase, product_id: i64) ?Product {
    for (db.products.items) |product| {
        if (product.product_id == product_id) return product;
    }
    return null;
}

fn findOrderDetailByAutoId(db: *const LegacyDatabase, autoid: i64) ?usize {
    for (db.orderdetails.items, 0..) |detail, index| {
        if (detail.autoid == autoid) return index;
    }
    return null;
}

fn removeOrderDetailsByOrderId(db: *LegacyDatabase, allocator: std.mem.Allocator, order_id: []const u8) void {
    var i: usize = 0;
    while (i < db.orderdetails.items.len) {
        if (std.ascii.eqlIgnoreCase(db.orderdetails.items[i].order_id, order_id)) {
            allocator.free(db.orderdetails.items[i].order_id);
            _ = db.orderdetails.orderedRemove(i);
            continue;
        }
        i += 1;
    }
}

fn extractQuotedLiteral(lower: []const u8, original: []const u8, marker: []const u8) ?[]const u8 {
    const start = std.mem.indexOf(u8, lower, marker) orelse return null;
    var i = start + marker.len;
    while (i < original.len and original[i] != '\'') : (i += 1) {}
    if (i >= original.len) return null;
    const begin = i + 1;
    i = begin;
    while (i < original.len and original[i] != '\'') : (i += 1) {}
    if (i > original.len) return null;
    return original[begin..i];
}

fn extractBetween(lower: []const u8, original: []const u8, start_marker: []const u8, end_marker: []const u8) ?[]const u8 {
    const start = std.mem.indexOf(u8, lower, start_marker) orelse return null;
    const begin = start + start_marker.len;
    const tail = lower[begin..];
    const end_rel = std.mem.indexOf(u8, tail, end_marker) orelse return null;
    return original[begin .. begin + end_rel];
}

fn productMatchesDescription(product: Product, needle: []const u8) bool {
    return std.ascii.indexOfIgnoreCase(product.description, needle) != null;
}

fn toLowerCopy(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    const lower = try allocator.dupe(u8, text);
    _ = std.ascii.lowerString(lower, lower);
    return lower;
}

fn evaluateSelect(
    allocator: std.mem.Allocator,
    db: *const LegacyDatabase,
    sql: []const u8,
    args: []const value.Value,
    rows: *std.ArrayList(Row),
) anyerror!void {
    const lower = try toLowerCopy(allocator, sql);
    defer allocator.free(lower);

    if (std.mem.startsWith(u8, lower, "select * from cart_configuration")) {
        if (db.configuration) |config| {
            try appendConfigRow(allocator, rows, config);
        }
        return;
    }

    if (std.mem.startsWith(u8, lower, "select * from cart_categories")) {
        for (db.categories.items) |category| {
            var fields: std.ArrayList(Field) = .empty;
            errdefer {
                for (fields.items) |field| {
                    allocator.free(field.name);
                    freeValue(allocator, field.value);
                }
                fields.deinit(allocator);
            }
            try addField(allocator, &fields, "categoryid", .{ .integer = category.category_id });
            try addField(allocator, &fields, "categoryname", .{ .string = category.category_name });
            try rows.append(allocator, .{ .fields = try fields.toOwnedSlice(allocator) });
        }
        return;
    }

    if (std.mem.startsWith(u8, lower, "select * from cart_products where description like '%")) {
        const needle = extractBetween(lower, sql, "select * from cart_products where description like '%", "%' order by modelname") orelse "";
        const copy = try allocator.dupe(Product, db.products.items);
        defer allocator.free(copy);
        std.sort.insertion(Product, copy, {}, struct {
            fn lessThan(_: void, lhs: Product, rhs: Product) bool {
                return std.ascii.lessThanIgnoreCase(lhs.model_name, rhs.model_name);
            }
        }.lessThan);
        for (copy) |product| {
            if (productMatchesDescription(product, needle)) {
                try appendProductRow(allocator, rows, product);
            }
        }
        return;
    }

    if (std.mem.startsWith(u8, lower, "select * from cart_products order by modelname")) {
        const copy = try allocator.dupe(Product, db.products.items);
        defer allocator.free(copy);
        std.sort.insertion(Product, copy, {}, struct {
            fn lessThan(_: void, lhs: Product, rhs: Product) bool {
                return std.ascii.lessThanIgnoreCase(lhs.model_name, rhs.model_name);
            }
        }.lessThan);
        try appendProductSlice(allocator, rows, copy);
        return;
    }

    if (std.mem.startsWith(u8, lower, "select * from cart_products where productid = ?")) {
        const product_id = if (args.len >= 1) parseIntValue(args[0]) else 0;
        if (findProductById(db, product_id)) |product| {
            try appendProductRow(allocator, rows, product);
        }
        return;
    }

    if (std.mem.startsWith(u8, lower, "select * from cart_products where productid = '")) {
        const literal = extractQuotedLiteral(lower, sql, "select * from cart_products where productid = '") orelse "";
        const product_id = std.fmt.parseInt(i64, literal, 10) catch 0;
        if (findProductById(db, product_id)) |product| {
            try appendProductRow(allocator, rows, product);
        }
        return;
    }

    if (std.mem.startsWith(u8, lower, "select * from cart_products where categoryid=? order by modelname")) {
        const category_id = if (args.len >= 1) parseIntValue(args[0]) else 0;
        const copy = try allocator.dupe(Product, db.products.items);
        defer allocator.free(copy);
        std.sort.insertion(Product, copy, {}, struct {
            fn lessThan(_: void, lhs: Product, rhs: Product) bool {
                return std.ascii.lessThanIgnoreCase(lhs.model_name, rhs.model_name);
            }
        }.lessThan);
        for (copy) |product| {
            if (product.category_id == category_id) {
                try appendProductRow(allocator, rows, product);
            }
        }
        return;
    }

    if (std.mem.startsWith(u8, lower, "select * from cart_products where categoryid = ")) {
        const literal = extractQuotedLiteral(lower, sql, "select * from cart_products where categoryid = ") orelse "";
        const category_id = std.fmt.parseInt(i64, literal, 10) catch 0;
        const copy = try allocator.dupe(Product, db.products.items);
        defer allocator.free(copy);
        std.sort.insertion(Product, copy, {}, struct {
            fn lessThan(_: void, lhs: Product, rhs: Product) bool {
                return std.ascii.lessThanIgnoreCase(lhs.model_name, rhs.model_name);
            }
        }.lessThan);
        for (copy) |product| {
            if (product.category_id == category_id) {
                try appendProductRow(allocator, rows, product);
            }
        }
        return;
    }

    if (std.mem.startsWith(u8, lower, "select * from cart_orderdetails where orderstate = 0 and productid = ? and orderid=?")) {
        const product_id = if (args.len >= 1) parseIntValue(args[0]) else 0;
        const order_id = if (args.len >= 2) try textFromValue(allocator, args[1]) else try allocator.dupe(u8, "");
        defer allocator.free(order_id);
        for (db.orderdetails.items) |detail| {
            if (detail.orderstate == 0 and detail.product_id == product_id and std.ascii.eqlIgnoreCase(detail.order_id, order_id)) {
                try appendOrderDetailRow(allocator, rows, detail);
            }
        }
        return;
    }

    if (std.mem.startsWith(u8, lower, "select * from cart_orderdetails where orderstate = 0 and productid = ")) {
        const product_marker = "select * from cart_orderdetails where orderstate = 0 and productid = ";
        const order_marker = " and orderid = ";
        const product_literal = extractBetween(lower, sql, product_marker, order_marker) orelse "";
        const product_id = std.fmt.parseInt(i64, product_literal, 10) catch 0;
        const order_literal = extractQuotedLiteral(lower, sql, order_marker) orelse "";
        for (db.orderdetails.items) |detail| {
            if (detail.orderstate == 0 and detail.product_id == product_id and std.ascii.eqlIgnoreCase(detail.order_id, order_literal)) {
                try appendOrderDetailRow(allocator, rows, detail);
            }
        }
        return;
    }

    if (std.mem.startsWith(u8, lower, "select orderid, productid from cart_orderdetails where orderstate=1 and productid='")) {
        const literal = extractQuotedLiteral(lower, sql, "select orderid, productid from cart_orderdetails where orderstate=1 and productid='") orelse "";
        const product_id = std.fmt.parseInt(i64, literal, 10) catch 0;
        for (db.orderdetails.items) |detail| {
            if (detail.orderstate == 1 and detail.product_id == product_id) {
                var fields: std.ArrayList(Field) = .empty;
                errdefer {
                    for (fields.items) |field| {
                        allocator.free(field.name);
                        freeValue(allocator, field.value);
                    }
                    fields.deinit(allocator);
                }
                try addField(allocator, &fields, "orderid", .{ .string = detail.order_id });
                try addField(allocator, &fields, "productid", .{ .integer = detail.product_id });
                try rows.append(allocator, .{ .fields = try fields.toOwnedSlice(allocator) });
            }
        }
        return;
    }

    if (std.mem.startsWith(u8, lower, "select cart_orderdetails.autoid,cart_orderdetails.orderid, cart_orderdetails.productid, cart_orderdetails.quantity as qty, cart_products.modelname, cart_products.unitcost, cart_orderdetails.orderid from cart_products inner join cart_orderdetails on cart_products.productid = cart_orderdetails.productid where cart_orderdetails.orderid = '")) {
        const order_id = extractQuotedLiteral(lower, sql, "select cart_orderdetails.autoid,cart_orderdetails.orderid, cart_orderdetails.productid, cart_orderdetails.quantity as qty, cart_products.modelname, cart_products.unitcost, cart_orderdetails.orderid from cart_products inner join cart_orderdetails on cart_products.productid = cart_orderdetails.productid where cart_orderdetails.orderid = '") orelse "";
        for (db.orderdetails.items) |detail| {
            if (!std.ascii.eqlIgnoreCase(detail.order_id, order_id)) continue;
            if (findProductById(db, detail.product_id)) |product| {
                try appendJoinRow(allocator, rows, detail, product);
            }
        }
        return;
    }

    return error.InvalidData;
}

fn applyMutation(
    allocator: std.mem.Allocator,
    db: *LegacyDatabase,
    sql: []const u8,
    args: []const value.Value,
) anyerror!void {
    const lower = try toLowerCopy(allocator, sql);
    defer allocator.free(lower);

    if (std.mem.startsWith(u8, lower, "insert into cart_orderdetails(orderid,productid,quantity) values(?,?,?)")) {
        const order_id: []u8 = if (args.len >= 1) try textFromValue(allocator, args[0]) else try allocator.dupe(u8, "");
        errdefer allocator.free(order_id);
        const product_id = if (args.len >= 2) parseIntValue(args[1]) else 0;
        const quantity = if (args.len >= 3) parseIntValue(args[2]) else 0;
        try db.orderdetails.append(allocator, .{
            .autoid = db.next_orderdetail_id,
            .orderstate = 0,
            .order_id = order_id,
            .product_id = product_id,
            .quantity = quantity,
        });
        db.next_orderdetail_id += 1;
        return;
    }

    if (std.mem.startsWith(u8, lower, "delete from cart_orderdetails where autoid = ?")) {
        const autoid = if (args.len >= 1) parseIntValue(args[0]) else 0;
        var i: usize = 0;
        while (i < db.orderdetails.items.len) {
            if (db.orderdetails.items[i].autoid == autoid) {
                allocator.free(db.orderdetails.items[i].order_id);
                _ = db.orderdetails.orderedRemove(i);
                continue;
            }
            i += 1;
        }
        return;
    }

    if (std.mem.startsWith(u8, lower, "delete from cart_orderdetails where orderid = ?")) {
        const order_id: []u8 = if (args.len >= 1) try textFromValue(allocator, args[0]) else try allocator.dupe(u8, "");
        defer allocator.free(order_id);
        removeOrderDetailsByOrderId(db, allocator, order_id);
        return;
    }

    if (std.mem.startsWith(u8, lower, "delete from cart_orderdetails where orderid = '")) {
        const order_id = extractQuotedLiteral(lower, sql, "delete from cart_orderdetails where orderid = '") orelse "";
        removeOrderDetailsByOrderId(db, allocator, order_id);
        return;
    }

    if (std.mem.startsWith(u8, lower, "update cart_orderdetails set quantity=? where productid=? and orderstate=0 and orderid =?")) {
        const quantity = if (args.len >= 1) parseIntValue(args[0]) else 0;
        const product_id = if (args.len >= 2) parseIntValue(args[1]) else 0;
        const order_id: []u8 = if (args.len >= 3) try textFromValue(allocator, args[2]) else try allocator.dupe(u8, "");
        defer allocator.free(order_id);
        for (db.orderdetails.items) |*detail| {
            if (detail.orderstate == 0 and detail.product_id == product_id and std.ascii.eqlIgnoreCase(detail.order_id, order_id)) {
                detail.quantity = quantity;
            }
        }
        return;
    }

    if (std.mem.startsWith(u8, lower, "update cart_orderdetails set quantity='")) {
        const quantity_literal = extractQuotedLiteral(lower, sql, "update cart_orderdetails set quantity='") orelse "";
        const autoid_marker = " where autoid ='";
        const autoid_literal = extractQuotedLiteral(lower, sql, autoid_marker) orelse "";
        const quantity = std.fmt.parseInt(i64, quantity_literal, 10) catch 0;
        const autoid = std.fmt.parseInt(i64, autoid_literal, 10) catch 0;
        if (findOrderDetailByAutoId(db, autoid)) |index| {
            db.orderdetails.items[index].quantity = quantity;
        }
        return;
    }

    return error.InvalidData;
}

pub fn recordsetExecute(self: *RecordsetState, allocator: std.mem.Allocator, args: []const value.Value) anyerror!void {
    try self.connection.ensureFresh(allocator);
    clearRows(allocator, &self.rows);
    self.position = -1;
    try evaluateSelect(allocator, &self.connection.db, self.sql, args, &self.rows);
}

pub fn recordsetNext(self: *RecordsetState) void {
    if (self.position < @as(isize, @intCast(self.rows.items.len))) {
        self.position += 1;
    }
    self.connection.touch(dbspec.currentUnixSeconds());
}

pub fn recordsetCount(self: *const RecordsetState) i64 {
    return @as(i64, @intCast(self.rows.items.len));
}

pub fn recordsetEof(self: *const RecordsetState) bool {
    return self.rows.items.len == 0 or self.position >= @as(isize, @intCast(self.rows.items.len));
}

pub fn recordsetBof(self: *const RecordsetState) bool {
    return self.position < 0;
}

pub fn recordsetFieldValue(self: *const RecordsetState, prop: []const u8) value.Value {
    if (recordsetEof(self)) return .{ .none = {} };
    const row = self.rows.items[@as(usize, @intCast(self.position))];
    for (row.fields) |field| {
        if (std.ascii.eqlIgnoreCase(field.name, prop)) return field.value;
    }
    return .{ .none = {} };
}

pub fn ddlExecute(self: *DdlState, allocator: std.mem.Allocator, args: []const value.Value) anyerror!void {
    try self.connection.ensureFresh(allocator);
    try applyMutation(allocator, &self.connection.db, self.sql, args);
}

pub fn deinitObject(allocator: std.mem.Allocator, object: value.ObjectValue) void {
    switch (object.kind) {
        .connection => {
            const state = @as(*ConnectionState, @ptrCast(@alignCast(object.ptr)));
            state.deinit(allocator);
            allocator.destroy(state);
        },
        .recordset => {
            const state = @as(*RecordsetState, @ptrCast(@alignCast(object.ptr)));
            clearRows(allocator, &state.rows);
            state.rows.deinit(allocator);
            allocator.free(state.sql);
            allocator.destroy(state);
        },
        .ddl => {
            const state = @as(*DdlState, @ptrCast(@alignCast(object.ptr)));
            allocator.free(state.sql);
            allocator.destroy(state);
        },
        .array, .map => {},
        .file => {},
    }
}

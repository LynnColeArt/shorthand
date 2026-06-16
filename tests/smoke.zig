const std = @import("std");
const short = @import("short");

test "value truthiness matches legacy nullish rules" {
    try std.testing.expect(!short.value.isTruthy(.{ .none = {} }));
    try std.testing.expect(short.value.isTruthy(.{ .boolean = true }));
    try std.testing.expect(short.value.isTruthy(.{ .integer = 7 }));
    try std.testing.expect(!short.value.isTruthy(.{ .string = "" }));
}

test "html escaping keeps output safe" {
    var buf: [64]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);

    try short.render.escapeHtml(&writer, "<tag & \"quote\">");
    try std.testing.expectEqualStrings("&lt;tag &amp; &quot;quote&quot;&gt;", writer.buffered());
}

test "request context has legacy defaults" {
    const req = short.request.RequestContext{};
    try std.testing.expect(req.legacy_mode);
    try std.testing.expectEqualStrings("GET", req.method);
    try std.testing.expectEqualStrings("", req.user_agent);
}

test "deployment profile defaults to CGI" {
    const profile = short.deployment.DeploymentProfile{};
    try std.testing.expectEqual(short.deployment.DeploymentMode.cgi, profile.mode);
    try std.testing.expect(profile.buffer_headers);
    try std.testing.expect(profile.stream_output);
}

test "response state keeps header timing separate from body output" {
    var state = short.response.ResponseState{};
    defer state.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(u16, 200), state.status_code);
    try std.testing.expectEqualStrings("text/html", state.content_type);
    try std.testing.expect(state.canMutateHeaders());

    try state.setHeader(std.testing.allocator, "X-Test", "alpha");
    try state.setCookie(std.testing.allocator, .{
        .name = "session",
        .value = "abc",
        .path = "/",
        .secure = true,
    });
    try state.redirect(std.testing.allocator, "/next");

    var buf: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buf);
    try state.writeHeaders(&writer);

    try std.testing.expect(!state.canMutateHeaders());
    try std.testing.expect(state.headers_committed);
    try std.testing.expectEqualStrings(
        "Status: 302 Found\r\nContent-Type: text/html\r\nX-Test: alpha\r\nLocation: /next\r\nSet-Cookie: session=abc; Path=/; Secure\r\n\r\n",
        writer.buffered(),
    );

    try std.testing.expectError(
        short.response.Error.HeadersAlreadySent,
        state.setHeader(std.testing.allocator, "X-After", "nope"),
    );
}

test "runtime groups deployment request and response state" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{
        .deployment = .{
            .mode = .abyss,
            .server_software = "Abyss/2.0",
            .document_root = "/srv/www",
        },
        .request = .{
            .method = "POST",
            .path_info = "/cart",
        },
        .response = .{
            .content_type = "text/plain",
        },
    });
    defer runtime.deinit();

    try std.testing.expectEqual(short.deployment.DeploymentMode.abyss, runtime.context.deployment.mode);
    try std.testing.expectEqualStrings("Abyss/2.0", runtime.context.deployment.server_software);
    try std.testing.expectEqualStrings("POST", runtime.context.request.method);
    try std.testing.expectEqualStrings("/cart", runtime.context.request.path_info);
    try std.testing.expectEqualStrings("text/plain", runtime.context.response.content_type);
}

test "runtime renders template output before headers are emitted" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source = "<~ header(\"X-Test\", \"alpha\") ~>Hello <%= \"world\" %>!";
    var body_buf: [256]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("Hello world!", body_writer.buffered());

    var header_buf: [256]u8 = undefined;
    var header_writer: std.Io.Writer = .fixed(&header_buf);
    try runtime.writeHeaders(&header_writer);
    try std.testing.expectEqualStrings("Content-Type: text/html\r\nX-Test: alpha\r\n\r\n", header_writer.buffered());
}

test "runtime supports legacy bootstrap helpers and for loops" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\total = 0
        \\for i = 1 to 3
        \\  total = total + i
        \\end for
        \\sidCookie = new Cookie("sid", "abc", AddMinutes(now(), 30))
        \\setcookie(sidCookie)
        \\~><%= total %>
    ;

    var body_buf: [256]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("6", body_writer.buffered());

    var header_buf: [512]u8 = undefined;
    var header_writer: std.Io.Writer = .fixed(&header_buf);
    try runtime.writeHeaders(&header_writer);
    try std.testing.expect(std.mem.indexOf(u8, header_writer.buffered(), "Set-Cookie: sid=abc; Expires=") != null);
}

test "runtime keeps legacy loose typing by default" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\total = "5" + 2
        \\~><%= total %>
    ;

    var body_buf: [128]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("7", body_writer.buffered());
}

test "runtime strips shebang before parsing" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\#!/usr/bin/env short run
        \\<~
        \\header("X-Test", "alpha")
        \\~>hello
    ;

    var body_buf: [64]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("hello", body_writer.buffered());

    var header_buf: [128]u8 = undefined;
    var header_writer: std.Io.Writer = .fixed(&header_buf);
    try runtime.writeHeaders(&header_writer);
    try std.testing.expectEqualStrings("Content-Type: text/html\r\nX-Test: alpha\r\n\r\n", header_writer.buffered());
}

test "runtime strict typing rejects implicit numeric coercion" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{
        .strict_typing = true,
    });
    defer runtime.deinit();

    const source =
        \\<~
        \\total = "5" + 2
        \\~><%= total %>
    ;

    var body_buf: [128]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try std.testing.expectError(error.StrictTypeMismatch, runtime.runSource(source, &body_writer));
}

test "runtime strict typing rejects header coercion" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{
        .strict_typing = true,
    });
    defer runtime.deinit();

    const source =
        \\<~
        \\header("X-Test", 2)
        \\~>
    ;

    var body_buf: [64]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try std.testing.expectError(error.StrictTypeMismatch, runtime.runSource(source, &body_writer));
}

test "runtime strict typing rejects redirect coercion" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{
        .strict_typing = true,
    });
    defer runtime.deinit();

    const source =
        \\<~
        \\redirect(123)
        \\~>
    ;

    var body_buf: [64]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try std.testing.expectError(error.StrictTypeMismatch, runtime.runSource(source, &body_writer));
}

test "runtime strict typing rejects setcookie coercion" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{
        .strict_typing = true,
    });
    defer runtime.deinit();

    const source =
        \\<~
        \\setcookie(1, 2)
        \\~>
    ;

    var body_buf: [64]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try std.testing.expectError(error.StrictTypeMismatch, runtime.runSource(source, &body_writer));
}

test "runtime reads request cookies and rewrites them" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{
        .request = .{
            .cookie_header = "theme=dark; shorthand_visits=2",
        },
    });
    defer runtime.deinit();

    const source =
        \\<~
        \\visits = int(getcookie("shorthand_visits")) + 1
        \\setcookie(new Cookie("shorthand_visits", string(visits), AddMinutes(now(), 30), "/"))
        \\~><%= visits %>
    ;

    var body_buf: [128]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("3", body_writer.buffered());

    var header_buf: [256]u8 = undefined;
    var header_writer: std.Io.Writer = .fixed(&header_buf);
    try runtime.writeHeaders(&header_writer);
    try std.testing.expect(std.mem.indexOf(u8, header_writer.buffered(), "Set-Cookie: shorthand_visits=3; Expires=") != null);
    try std.testing.expect(std.mem.indexOf(u8, header_writer.buffered(), "; Path=/") != null);
}

test "runtime browser post echo escapes user input" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{
        .request = .{
            .body = "message=Hello+%26+%3CWorld%3E+%22quotes%22+%27apostrophe%27",
        },
    });
    defer runtime.deinit();

    const source =
        \\<~
        \\message = urldecode(f("message"))
        \\safe = replace(replace(replace(replace(message, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"), "'", "&#39;")
        \\~><pre><%= safe %></pre>
    ;

    var body_buf: [256]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings(
        "<pre>Hello &amp; &lt;World&gt; \"quotes\" &#39;apostrophe&#39;</pre>",
        body_writer.buffered(),
    );
}

test "runtime browser redirect demo stops body output" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{
        .request = .{
            .body = "bounce=1",
        },
    });
    defer runtime.deinit();

    const source =
        \\<~
        \\if len(urldecode(f("bounce"))) > 0 then
        \\    redirect("/redirect-complete.short")
        \\    exit()
        \\end if
        \\~>Should not appear
    ;

    var body_buf: [64]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);
    try std.testing.expectEqualStrings("", body_writer.buffered());

    var header_buf: [128]u8 = undefined;
    var header_writer: std.Io.Writer = .fixed(&header_buf);
    try runtime.writeHeaders(&header_writer);
    try std.testing.expect(std.mem.indexOf(u8, header_writer.buffered(), "Status: 302 Found") != null);
    try std.testing.expect(std.mem.indexOf(u8, header_writer.buffered(), "Location: /redirect-complete.short") != null);
}

test "runtime browser regex search filters catalog entries" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{
        .request = .{
            .query_string = "term=Cookie",
        },
    });
    defer runtime.deinit();

    const source =
        \\<~
        \\term = urldecode(q("term"))
        \\catalog = new Array("Apache virtual host", "Cookie counter", "POST echo", "Redirect bounce")
        \\matches = 0
        \\for i = 1 to size(catalog)
        \\    if regexmatch("(?i)" & term, catalog[i]) then
        \\        matches = matches + 1
        \\    end if
        \\end for
        \\~><%= matches %>|<%= regexextract("(?i)(" & term & ")", "Cookie counter", 1) %>
    ;

    var body_buf: [128]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("1|Cookie", body_writer.buffered());
}

test "runtime can query the legacy cart database" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\conn = new Connection("MySQL", "database=smoses_secondary;server=localhost;uid=root;pwd=;")
        \\core = new Recordset(conn, "Select * from cart_configuration")
        \\core.execute()
        \\core.next()
        \\~><%= core.currency %>
    ;

    var body_buf: [256]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("$", body_writer.buffered());
}

test "runtime can query the legacy category list" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\conn = new Connection("MySQL", "database=smoses_secondary;server=localhost;uid=root;pwd=;")
        \\category = new Recordset(conn, "Select * from cart_categories")
        \\category.execute()
        \\category.next()
        \\~><%= category.categoryname %>
    ;

    var body_buf: [256]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("Communication Tools", body_writer.buffered());
}

test "legacy db connections self-manage refresh policy" {
    const conn_object = try short.db.createConnection(
        std.testing.allocator,
        "MySQL",
        "database=smoses_secondary;server=localhost;uid=root;pwd=;idle_timeout=0;max_age=0",
    );
    defer short.db.deinitObject(std.testing.allocator, conn_object);

    const conn = short.db.connectionFromValue(.{ .object = conn_object }) orelse return error.TestFailure;
    const before = short.db.connectionStatus(conn);
    try std.testing.expectEqual(short.dbspec.BackendKind.mysql, before.backend);
    try std.testing.expectEqual(@as(u64, 0), before.refresh_count);
    try std.testing.expectEqual(@as(u64, 0), before.policy.idle_timeout_seconds.?);
    try std.testing.expectEqual(@as(u64, 0), before.policy.max_age_seconds.?);

    const rs_object = try short.db.createRecordset(std.testing.allocator, conn, "Select * from cart_configuration");
    defer short.db.deinitObject(std.testing.allocator, rs_object);

    const rs = short.db.recordsetFromValue(.{ .object = rs_object }) orelse return error.TestFailure;
    try short.db.recordsetExecute(rs, std.testing.allocator, &.{});

    const after = short.db.connectionStatus(conn);
    try std.testing.expectEqual(@as(u64, 1), after.refresh_count);
    try std.testing.expectEqual(@as(u64, 1), after.generation);
    try std.testing.expect(after.last_refresh_at >= before.last_refresh_at);
}

test "connection properties expose backend and freshness state" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\conn = new Connection("MySQL", "database=smoses_secondary;server=localhost;uid=root;pwd=;idle_timeout=0;max_age=0")
        \\core = new Recordset(conn, "Select * from cart_configuration")
        \\core.execute()
        \\~><%= conn.backend %>|<%= conn.refresh_count %>|<%= conn.stale %>
    ;

    var body_buf: [128]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("mysql|1|true", body_writer.buffered());
}

test "runtime regex match supports Perl-style flags" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\ok = regexmatch("(?i)^[a-z]+$", "AbC")
        \\~><%= ok %>
    ;

    var body_buf: [128]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("true", body_writer.buffered());
}

test "runtime regex valid reports compile failures" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\good = regexvalid("(?i)^[a-z]+$")
        \\bad = regexvalid("(")
        \\~><%= good %>|<%= bad %>
    ;

    var body_buf: [128]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("true|false", body_writer.buffered());
}

test "runtime regex replace supports captures" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\out = regexreplace("([0-9]+)", "[$1]", "a1b22c")
        \\~><%= out %>
    ;

    var body_buf: [128]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("a[1]b[22]c", body_writer.buffered());
}

test "runtime regex extract returns full match and named capture" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\whole = regexextract("(?<word>[a-z]+)([0-9]+)", "abc123")
        \\word = regexcapture("(?<word>[a-z]+)([0-9]+)", "abc123", "word")
        \\~><%= whole %>|<%= word %>
    ;

    var body_buf: [128]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("abc123|abc", body_writer.buffered());
}

test "runtime numeric helpers compare and bound values" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\float_hi = max(1, 3.5, 2)
        \\string_hi = max(1, "7", 2)
        \\lo = min("7", 3.5, 2)
        \\zero = rand(0)
        \\same = rand(5, 5)
        \\bounded = rand(10, 5)
        \\safe = rand() >= 0
        \\~><%= float_hi %>|<%= string_hi %>|<%= lo %>|<%= zero %>|<%= same %>|<%= bounded >= 5 and bounded <= 10 %>|<%= safe %>
    ;

    var body_buf: [256]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("3.5|7|2|0|5|true|true", body_writer.buffered());
}

test "runtime strict typing rejects numeric helper coercion" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{
        .strict_typing = true,
    });
    defer runtime.deinit();

    const source =
        \\<~
        \\max(1, "2")
        \\~>
    ;

    var body_buf: [64]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try std.testing.expectError(error.StrictTypeMismatch, runtime.runSource(source, &body_writer));
}

test "runtime text helpers match manual semantics" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\replaced = replace("The Big Brown Brown Fox", "Brown", "Red")
        \\pos1 = strpos(replaced, "Red")
        \\pos2 = strpos(replaced, "brown")
        \\translated = translate("The Big Brown Fox", "B", "b")
        \\lowered = lc("MiXeD")
        \\uppered = uc("MiXeD")
        \\stringed = string(123)
        \\formatted = format(500, 2)
        \\~><%= replaced %>|<%= pos1 %>|<%= pos2 %>|<%= translated %>|<%= lowered %>|<%= uppered %>|<%= stringed %>|<%= formatted %>
    ;

    var body_buf: [256]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("The Big Red Red Fox|8|-1|The big brown Fox|mixed|MIXED|123|500.00", body_writer.buffered());
}

test "runtime date helpers parse and format legacy forms" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\d = date("2002-09-15 14:00:00")
        \\pretty = FormatDate(d, "%A, %B %#d, %Y %I:%M:%S %p")
        \\~><%= pretty %>
    ;

    var body_buf: [256]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("Sunday, September 15, 2002 02:00:00 PM", body_writer.buffered());
}

test "runtime file helpers check readability and size" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\exists = FileExists("README.md")
        \\size_ok = FileSize("README.md") > 0
        \\missing = FileExists("definitely-missing.short")
        \\missing_size = FileSize("definitely-missing.short")
        \\~><%= exists %>|<%= size_ok %>|<%= missing %>|<%= missing_size %>
    ;

    var body_buf: [256]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("true|true|false|-1", body_writer.buffered());
}

test "runtime file object supports constructor read write rewind and error state" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(std.testing.io, .{
        .sub_path = "input.txt",
        .data = "alpha\r\nbeta\x00gamma\nend",
        .flags = .{ .read = true },
    });

    const input_path = try tmp.dir.realPathFileAlloc(std.testing.io, "input.txt", std.testing.allocator);
    defer std.testing.allocator.free(input_path);

    const parent_dir = std.fs.path.dirname(input_path).?;
    const output_path = try std.fs.path.join(std.testing.allocator, &.{ parent_dir, "output.txt" });
    defer std.testing.allocator.free(output_path);
    const missing_path = try std.fs.path.join(std.testing.allocator, &.{ parent_dir, "missing.txt" });
    defer std.testing.allocator.free(missing_path);

    const source = try std.fmt.allocPrint(std.testing.allocator,
        \\<~
        \\infile = new File("{s}")
        \\line1 = infile.readln()
        \\mid_eof = infile.eof()
        \\line2 = infile.readln()
        \\infile.rewind()
        \\all = infile.read()
        \\end_eof = infile.eof()
        \\outfile = new File("{s}", "w+")
        \\written = outfile.write("hello")
        \\outfile.rewind()
        \\replayed = outfile.read()
        \\mode_ok = outfile.mode = "w+"
        \\name_ok = strpos(outfile.name, "output.txt") >= 0
        \\error_ok = length(outfile.error) = 0
        \\outfile.close()
        \\missing = new File("{s}")
        \\missing_error = length(missing.error) > 0
        \\~><%= line1 %>|<%= line2 %>|<%= all %>|<%= mid_eof %>|<%= end_eof %>|<%= written %>|<%= replayed %>|<%= mode_ok %>|<%= name_ok %>|<%= error_ok %>|<%= missing_error %>
    , .{ input_path, output_path, missing_path });
    defer std.testing.allocator.free(source);

    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    var body_buf: [512]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings(
        "alpha|beta|alpha\r\nbeta|false|true|5|hello|true|true|true|true",
        body_writer.buffered(),
    );
}

test "runtime arrays use square brackets and management helpers" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\a = new Array(10, 20, 30)
        \\nested = new Array()
        \\a[2] = a[2] + 1
        \\nested[1][1] = 42
        \\shape_text = shape(a)
        \\lbound_text = lbound(a)
        \\ubound_text = ubound(a)
        \\allocated_text = allocated(a)
        \\~><%= a[2] %>|<%= size(a) %>|<%= a.count %>|<%= shape_text %>|<%= lbound_text %>|<%= ubound_text %>|<%= allocated_text %>|<%= nested[1][1] %>
    ;

    var body_buf: [256]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("21|3|3|[3]|[1]|[3]|true|42", body_writer.buffered());
}

test "runtime maps use square brackets and associative helpers" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\m = new Map("x", 1, "y", 2)
        \\m["db"]["host"] = "localhost"
        \\m["db"]["port"] = 5432
        \\keys_text = keys(m)
        \\values_text = values(m)
        \\had_y = contains(m, "y")
        \\removed = remove(m, "x")
        \\missing_x = contains(m, "x")
        \\count_text = m.count
        \\allocated_text = allocated(m)
        \\~><%= m["y"] %>|<%= m["db"]["host"] %>|<%= keys_text %>|<%= values_text %>|<%= had_y %>|<%= removed %>|<%= missing_x %>|<%= count_text %>|<%= allocated_text %>
    ;

    var body_buf: [512]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings(
        "2|localhost|[\"x\", \"y\", \"db\"]|[1, 2, {\"host\": \"localhost\", \"port\": 5432}]|true|true|false|2|true",
        body_writer.buffered(),
    );
}

test "runtime move_alloc transfers array allocation and deallocates source" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\from = new Array(10, 20, 30)
        \\to = new Array()
        \\move_alloc(from, to)
        \\from_alloc = allocated(from)
        \\to_alloc = allocated(to)
        \\~><%= from_alloc %>|<%= size(from) %>|<%= to_alloc %>|<%= size(to) %>|<%= to[2] %>
    ;

    var body_buf: [128]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("false|0|true|3|20", body_writer.buffered());
}

test "runtime move_alloc transfers map allocation and deallocates source" {
    var runtime = short.runtime.Runtime.init(std.testing.io, std.testing.allocator, .{});
    defer runtime.deinit();

    const source =
        \\<~
        \\from = new Map("a", 9)
        \\to = new Map()
        \\move_alloc(from, to)
        \\from_alloc = allocated(from)
        \\to_alloc = allocated(to)
        \\~><%= from_alloc %>|<%= size(from) %>|<%= to_alloc %>|<%= size(to) %>|<%= to["a"] %>
    ;

    var body_buf: [128]u8 = undefined;
    var body_writer: std.Io.Writer = .fixed(&body_buf);
    try runtime.runSource(source, &body_writer);

    try std.testing.expectEqualStrings("false|0|true|1|9", body_writer.buffered());
}

test "cgi adapter maps Apache and Abyss environments" {
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();

    try env.put("SERVER_SOFTWARE", "Abyss Web Server 2.0");
    try env.put("DOCUMENT_ROOT", "/var/www");
    try env.put("SCRIPT_FILENAME", "/var/www/index.short");
    try env.put("GATEWAY_INTERFACE", "CGI/1.1");
    try env.put("REQUEST_METHOD", "POST");
    try env.put("SCRIPT_NAME", "/index.short");
    try env.put("PATH_INFO", "/cart");
    try env.put("QUERY_STRING", "state=view");
    try env.put("REMOTE_ADDR", "127.0.0.1");
    try env.put("HTTP_USER_AGENT", "ShortHandTest/1.0");
    try env.put("SHORT_STRICT_TYPING", "1");

    const abyss_context = short.cgi.runtimeContextFromEnvironMap(&env);
    try std.testing.expectEqual(short.deployment.DeploymentMode.abyss, abyss_context.deployment.mode);
    try std.testing.expectEqualStrings("/var/www", abyss_context.deployment.document_root);
    try std.testing.expectEqualStrings("/var/www/index.short", abyss_context.deployment.script_filename);
    try std.testing.expectEqualStrings("POST", abyss_context.request.method);
    try std.testing.expectEqualStrings("/index.short", abyss_context.request.script_name);
    try std.testing.expectEqualStrings("/cart", abyss_context.request.path_info);
    try std.testing.expectEqualStrings("state=view", abyss_context.request.query_string);
    try std.testing.expectEqualStrings("127.0.0.1", abyss_context.request.remote_addr);
    try std.testing.expectEqualStrings("ShortHandTest/1.0", abyss_context.request.user_agent);
    try std.testing.expect(abyss_context.strict_typing);

    var apache_env = std.process.Environ.Map.init(std.testing.allocator);
    defer apache_env.deinit();

    try apache_env.put("SERVER_SOFTWARE", "Apache/2.4.58 (Unix)");
    const apache_context = short.cgi.runtimeContextFromEnvironMap(&apache_env);
    try std.testing.expectEqual(short.deployment.DeploymentMode.apache_module, apache_context.deployment.mode);
}

test "parser splits text and script chunks" {
    const source =
        \\Hello <~ print "world" ~>!
    ;
    var parser = short.parser.Parser.init(std.testing.allocator, source);
    var program = try parser.parse();
    defer program.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 3), program.chunks.len);

    try std.testing.expect(program.chunks[0] == .text);
    try std.testing.expectEqual(@as(usize, 0), program.chunks[0].text.start);
    try std.testing.expectEqual(@as(usize, 6), program.chunks[0].text.end);

    try std.testing.expect(program.chunks[1] == .script);
    try std.testing.expectEqual(short.ast.TagStyle.tilde, program.chunks[1].script.style);
    try std.testing.expectEqual(short.ast.ScriptKind.block, program.chunks[1].script.kind);
    try std.testing.expectEqual(@as(usize, 8), program.chunks[1].script.span.start);
    try std.testing.expectEqual(@as(usize, 23), program.chunks[1].script.span.end);

    try std.testing.expect(program.chunks[2] == .text);
    try std.testing.expectEqualStrings("!", source[program.chunks[2].text.start..program.chunks[2].text.end]);
}

test "parser recognizes percent and question print tags" {
    const source =
        \\A <%= x %> B <?= y ?> C
    ;
    var parser = short.parser.Parser.init(std.testing.allocator, source);
    var program = try parser.parse();
    defer program.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 5), program.chunks.len);

    try std.testing.expect(program.chunks[1] == .script);
    try std.testing.expectEqual(short.ast.TagStyle.percent, program.chunks[1].script.style);
    try std.testing.expectEqual(short.ast.ScriptKind.expr, program.chunks[1].script.kind);
    try std.testing.expectEqualStrings(" x ", source[program.chunks[1].script.span.start..program.chunks[1].script.span.end]);

    try std.testing.expect(program.chunks[3] == .script);
    try std.testing.expectEqual(short.ast.TagStyle.question, program.chunks[3].script.style);
    try std.testing.expectEqual(short.ast.ScriptKind.expr, program.chunks[3].script.kind);
    try std.testing.expectEqualStrings(" y ", source[program.chunks[3].script.span.start..program.chunks[3].script.span.end]);
}

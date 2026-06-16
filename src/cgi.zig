const std = @import("std");
const deployment = @import("deployment.zig");
const request = @import("request.zig");

pub const RuntimeContext = struct {
    deployment: deployment.DeploymentProfile = .{},
    request: request.RequestContext = .{},
    response: @import("response.zig").ResponseState = .{},
    strict_typing: bool = false,
};

fn envValue(environ_map: *const std.process.Environ.Map, key: []const u8) ?[]const u8 {
    return environ_map.get(key);
}

fn envFlag(environ_map: *const std.process.Environ.Map, key: []const u8) bool {
    const raw = envValue(environ_map, key) orelse return false;
    return std.ascii.eqlIgnoreCase(raw, "1") or
        std.ascii.eqlIgnoreCase(raw, "true") or
        std.ascii.eqlIgnoreCase(raw, "yes") or
        std.ascii.eqlIgnoreCase(raw, "on");
}

fn detectDeploymentMode(server_software: []const u8) deployment.DeploymentMode {
    if (std.ascii.indexOfIgnoreCase(server_software, "abyss") != null or
        std.ascii.indexOfIgnoreCase(server_software, "aprelium") != null)
    {
        return .abyss;
    }

    if (std.ascii.indexOfIgnoreCase(server_software, "apache") != null) {
        return .apache_module;
    }

    return .cgi;
}

pub fn deploymentProfileFromEnvironMap(environ_map: *const std.process.Environ.Map) deployment.DeploymentProfile {
    const server_software = envValue(environ_map, "SERVER_SOFTWARE") orelse "";
    return .{
        .mode = detectDeploymentMode(server_software),
        .server_software = server_software,
        .document_root = envValue(environ_map, "DOCUMENT_ROOT") orelse "",
        .script_filename = envValue(environ_map, "SCRIPT_FILENAME") orelse "",
        .gateway_interface = envValue(environ_map, "GATEWAY_INTERFACE") orelse "",
        .buffer_headers = true,
        .stream_output = true,
    };
}

pub fn requestContextFromEnvironMap(environ_map: *const std.process.Environ.Map) request.RequestContext {
    return .{
        .method = envValue(environ_map, "REQUEST_METHOD") orelse "GET",
        .script_name = envValue(environ_map, "SCRIPT_NAME") orelse "",
        .path_info = envValue(environ_map, "PATH_INFO") orelse "",
        .query_string = envValue(environ_map, "QUERY_STRING") orelse "",
        .body = "",
        .cookie_header = envValue(environ_map, "HTTP_COOKIE") orelse "",
        .remote_addr = envValue(environ_map, "REMOTE_ADDR") orelse "",
        .user_agent = envValue(environ_map, "HTTP_USER_AGENT") orelse "",
        .legacy_mode = true,
    };
}

pub fn runtimeContextFromEnvironMap(environ_map: *const std.process.Environ.Map) RuntimeContext {
    return .{
        .deployment = deploymentProfileFromEnvironMap(environ_map),
        .request = requestContextFromEnvironMap(environ_map),
        .strict_typing = envFlag(environ_map, "SHORT_STRICT_TYPING"),
    };
}

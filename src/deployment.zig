pub const DeploymentMode = enum {
    cgi,
    apache_module,
    abyss,
};

pub fn modeName(mode: DeploymentMode) []const u8 {
    return switch (mode) {
        .cgi => "cgi",
        .apache_module => "apache_module",
        .abyss => "abyss",
    };
}

pub const DeploymentProfile = struct {
    mode: DeploymentMode = .cgi,
    server_software: []const u8 = "",
    document_root: []const u8 = "",
    script_filename: []const u8 = "",
    gateway_interface: []const u8 = "",
    buffer_headers: bool = true,
    stream_output: bool = true,
};

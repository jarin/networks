const std = @import("std");
const network_module = @import("network.zig");
const Network = network_module.Network;
const Server = network_module.Server;
const ServerStatus = network_module.ServerStatus;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var network = Network.init(allocator);
    defer network.deinit();

    const address = try std.net.Address.parseIp("127.0.0.1", 8080);
    var listener = try address.listen(.{
        .reuse_address = true,
    });
    defer listener.deinit();

    std.debug.print("HTTP Server running on http://127.0.0.1:8080\n", .{});
    std.debug.print("API Endpoints:\n", .{});
    std.debug.print("  GET  /api/network        - Get full network state (nodes & links)\n", .{});
    std.debug.print("  GET  /api/stats          - Get network statistics\n", .{});
    std.debug.print("  POST /api/server         - Add a server (JSON: {{\"name\": \"...\", \"status\": \"online\"}})\n", .{});
    std.debug.print("  POST /api/link           - Connect servers (JSON: {{\"from\": 0, \"to\": 1}})\n", .{});
    std.debug.print("  POST /api/disconnect     - Disconnect server (JSON: {{\"server\": 0}})\n", .{});
    std.debug.print("  GET  /                   - Visualization dashboard\n", .{});
    std.debug.print("\nInitializing network with 100 servers...\n", .{});

    // Disney characters and Norse mythology names
    const server_names = [_][]const u8{
        "mickey", "minnie", "donald", "daisy", "goofy", "pluto", "ariel", "belle", "jasmine", "aurora",
        "mulan", "tiana", "merida", "elsa", "anna", "moana", "rapunzel", "cinderella", "snow-white", "pocahontas",
        "simba", "nala", "timon", "pumbaa", "mufasa", "scar", "woody", "buzz", "jessie", "rex",
        "hamm", "slinky", "sulley", "mike", "boo", "nemo", "dory", "marlin", "crush", "bruce",
        "lightning", "mater", "sally", "doc", "ramone", "flo", "wall-e", "eve", "captain", "auto",
        "odin", "thor", "loki", "freya", "frigg", "baldur", "tyr", "heimdall", "hela", "vidar",
        "vali", "bragi", "idun", "njord", "skadi", "frey", "freyja", "sif", "magni", "modi",
        "forseti", "hodr", "hermod", "ullr", "vili", "ve", "buri", "bor", "bestla", "ymir",
        "fenrir", "jormungandr", "sleipnir", "ratatoskr", "hugin", "munin", "geri", "freki", "tanngrisnir", "tanngnjost",
        "gullinbursti", "hildisvini", "heidrun", "eikthyrnir", "arvak", "alsvid", "skinfaxi", "hrimfaxi", "garm", "nidhogg",
    };

    var server_ids: [100]u32 = undefined;
    var prng = std.Random.DefaultPrng.init(42);
    const random = prng.random();

    // Create 100 servers with random status
    for (server_names, 0..) |name, i| {
        const status_roll = random.uintLessThan(u8, 100);
        const status: ServerStatus = if (status_roll < 75)
            .online
        else if (status_roll < 90)
            .degraded
        else
            .offline;

        server_ids[i] = try network.add_server(name, status);
    }

    std.debug.print("Created 100 servers\n", .{});
    std.debug.print("Building network topology...\n", .{});

    // Create a more interesting topology:
    // 1. Ring topology connecting all servers
    for (0..100) |i| {
        const next = (i + 1) % 100;
        try network.connect_servers(server_ids[i], server_ids[next]);
    }

    // 2. Add some cross-connections for shortcuts (small-world network)
    for (0..50) |_| {
        const a = random.uintLessThan(usize, 100);
        var b = random.uintLessThan(usize, 100);
        while (b == a) {
            b = random.uintLessThan(usize, 100);
        }
        network.connect_servers(server_ids[a], server_ids[b]) catch {};
    }

    // 3. Create some hub nodes (connect every 10th server to neighbors)
    var hub: usize = 0;
    while (hub < 100) : (hub += 10) {
        for (0..5) |offset| {
            const target = (hub + offset + 1) % 100;
            if (target != hub) {
                network.connect_servers(server_ids[hub], server_ids[target]) catch {};
            }
        }
    }

    std.debug.print("Network topology created with ~200 links\n", .{});
    std.debug.print("Topology: Ring + random shortcuts + hub nodes\n\n", .{});

    while (true) {
        const connection = try listener.accept();
        try handle_request(allocator, &network, connection);
    }
}

fn handle_request(allocator: std.mem.Allocator, network: *Network, connection: std.net.Server.Connection) !void {
    defer connection.stream.close();

    var buffer: [4096]u8 = undefined;
    const bytes_read = try connection.stream.read(&buffer);

    if (bytes_read == 0) return;

    const request = buffer[0..bytes_read];

    // Parse HTTP method and path
    var lines = std.mem.splitScalar(u8, request, '\n');
    const first_line = lines.next() orelse return;

    var parts = std.mem.splitScalar(u8, first_line, ' ');
    const method = parts.next() orelse return;
    const path = parts.next() orelse return;

    // Find body if POST request
    const body_start = std.mem.indexOf(u8, request, "\r\n\r\n");
    const body = if (body_start) |start| request[start + 4 ..] else "";

    if (std.mem.eql(u8, method, "GET") and std.mem.startsWith(u8, path, "/api/network")) {
        try send_network_state(allocator, network, connection.stream);
    } else if (std.mem.eql(u8, method, "GET") and std.mem.startsWith(u8, path, "/api/stats")) {
        try send_stats(allocator, network, connection.stream);
    } else if (std.mem.eql(u8, method, "POST") and std.mem.startsWith(u8, path, "/api/server")) {
        try add_server_endpoint(allocator, network, connection.stream, body);
    } else if (std.mem.eql(u8, method, "POST") and std.mem.startsWith(u8, path, "/api/link")) {
        try link_servers_endpoint(allocator, network, connection.stream, body);
    } else if (std.mem.eql(u8, method, "POST") and std.mem.startsWith(u8, path, "/api/disconnect")) {
        try disconnect_server_endpoint(allocator, network, connection.stream, body);
    } else if (std.mem.eql(u8, method, "GET") and std.mem.eql(u8, path, "/")) {
        try send_html_dashboard(connection.stream);
    } else {
        try send_404(connection.stream);
    }
}

fn send_network_state(allocator: std.mem.Allocator, network: *Network, stream: std.net.Stream) !void {
    var json = std.ArrayList(u8).init(allocator);
    defer json.deinit();

    const writer = json.writer();

    try writer.writeAll("{\"nodes\":[");

    for (network.servers.items, 0..) |server, i| {
        if (i > 0) try writer.writeAll(",");
        const root_id = network.find_network_root(server.id) orelse server.id;
        try std.fmt.format(writer, "{{\"id\":{},\"name\":\"{s}\",\"status\":\"{s}\",\"group\":{}}}", .{
            server.id,
            server.name,
            @tagName(server.status),
            root_id,
        });
    }

    try writer.writeAll("],\"links\":[");

    var link_count: usize = 0;
    for (network.servers.items, 0..) |server_a, i| {
        for (network.servers.items[i + 1 ..]) |server_b| {
            if (network.are_connected(server_a.id, server_b.id)) {
                if (link_count > 0) try writer.writeAll(",");
                try std.fmt.format(writer, "{{\"source\":{},\"target\":{}}}", .{ server_a.id, server_b.id });
                link_count += 1;
            }
        }
    }

    try writer.writeAll("]}");

    const response = try std.fmt.allocPrint(allocator, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: {}\r\n\r\n{s}", .{ json.items.len, json.items });
    defer allocator.free(response);

    try stream.writeAll(response);
}

fn send_stats(allocator: std.mem.Allocator, network: *Network, stream: std.net.Stream) !void {
    const partitions = network.count_network_partitions();

    var online: u32 = 0;
    var offline: u32 = 0;
    var degraded: u32 = 0;

    for (network.servers.items) |server| {
        switch (server.status) {
            .online => online += 1,
            .offline => offline += 1,
            .degraded => degraded += 1,
        }
    }

    const json = try std.fmt.allocPrint(allocator, "{{\"servers\":{},\"links\":{},\"partitions\":{},\"online\":{},\"offline\":{},\"degraded\":{}}}", .{
        network.servers.items.len,
        network.links_count,
        partitions,
        online,
        offline,
        degraded,
    });
    defer allocator.free(json);

    const response = try std.fmt.allocPrint(allocator, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: {}\r\n\r\n{s}", .{ json.len, json });
    defer allocator.free(response);

    try stream.writeAll(response);
}

fn add_server_endpoint(allocator: std.mem.Allocator, network: *Network, stream: std.net.Stream, body: []const u8) !void {
    _ = allocator;

    // Simple JSON parsing for demo purposes
    const name_start = std.mem.indexOf(u8, body, "\"name\":\"");
    const status_start = std.mem.indexOf(u8, body, "\"status\":\"");

    if (name_start == null or status_start == null) {
        try send_error(stream, "Invalid JSON");
        return;
    }

    const name_value_start = name_start.? + 8;
    const name_end = std.mem.indexOfPos(u8, body, name_value_start, "\"") orelse {
        try send_error(stream, "Invalid name");
        return;
    };
    const name = body[name_value_start..name_end];

    const status_value_start = status_start.? + 10;
    const status_end = std.mem.indexOfPos(u8, body, status_value_start, "\"") orelse {
        try send_error(stream, "Invalid status");
        return;
    };
    const status_str = body[status_value_start..status_end];

    const status: ServerStatus = if (std.mem.eql(u8, status_str, "online"))
        .online
    else if (std.mem.eql(u8, status_str, "offline"))
        .offline
    else if (std.mem.eql(u8, status_str, "degraded"))
        .degraded
    else {
        try send_error(stream, "Invalid status value");
        return;
    };

    const server_id = try network.add_server(name, status);

    var buf: [256]u8 = undefined;
    const json = try std.fmt.bufPrint(&buf, "{{\"id\":{},\"name\":\"{s}\",\"status\":\"{s}\"}}", .{ server_id, name, @tagName(status) });

    var response_buf: [512]u8 = undefined;
    const response = try std.fmt.bufPrint(&response_buf, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: {}\r\n\r\n{s}", .{ json.len, json });

    try stream.writeAll(response);
}

fn link_servers_endpoint(allocator: std.mem.Allocator, network: *Network, stream: std.net.Stream, body: []const u8) !void {
    _ = allocator;

    const from_start = std.mem.indexOf(u8, body, "\"from\":");
    const to_start = std.mem.indexOf(u8, body, "\"to\":");

    if (from_start == null or to_start == null) {
        try send_error(stream, "Invalid JSON");
        return;
    }

    const from_value_start = from_start.? + 7;
    const to_value_start = to_start.? + 5;

    var from_end = from_value_start;
    while (from_end < body.len and body[from_end] >= '0' and body[from_end] <= '9') : (from_end += 1) {}

    var to_end = to_value_start;
    while (to_end < body.len and body[to_end] >= '0' and body[to_end] <= '9') : (to_end += 1) {}

    const from_id = try std.fmt.parseInt(u32, body[from_value_start..from_end], 10);
    const to_id = try std.fmt.parseInt(u32, body[to_value_start..to_end], 10);

    network.connect_servers(from_id, to_id) catch {
        try send_error(stream, "Failed to connect servers");
        return;
    };

    const json = "{\"success\":true}";
    var response_buf: [256]u8 = undefined;
    const response = try std.fmt.bufPrint(&response_buf, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: {}\r\n\r\n{s}", .{ json.len, json });

    try stream.writeAll(response);
}

fn disconnect_server_endpoint(allocator: std.mem.Allocator, network: *Network, stream: std.net.Stream, body: []const u8) !void {
    _ = allocator;

    const server_start = std.mem.indexOf(u8, body, "\"server\":");

    if (server_start == null) {
        try send_error(stream, "Invalid JSON");
        return;
    }

    const server_value_start = server_start.? + 9;
    var server_end = server_value_start;
    while (server_end < body.len and body[server_end] >= '0' and body[server_end] <= '9') : (server_end += 1) {}

    const server_id = try std.fmt.parseInt(u32, body[server_value_start..server_end], 10);

    network.disconnect_server(server_id) catch {
        try send_error(stream, "Server not found");
        return;
    };

    const json = "{\"success\":true}";
    var response_buf: [256]u8 = undefined;
    const response = try std.fmt.bufPrint(&response_buf, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: {}\r\n\r\n{s}", .{ json.len, json });

    try stream.writeAll(response);
}

fn send_error(stream: std.net.Stream, message: []const u8) !void {
    var buf: [512]u8 = undefined;
    const json = try std.fmt.bufPrint(&buf, "{{\"error\":\"{s}\"}}", .{message});

    var response_buf: [1024]u8 = undefined;
    const response = try std.fmt.bufPrint(&response_buf, "HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: {}\r\n\r\n{s}", .{ json.len, json });

    try stream.writeAll(response);
}

fn send_404(stream: std.net.Stream) !void {
    const response = "HTTP/1.1 404 Not Found\r\nContent-Length: 9\r\n\r\nNot Found";
    try stream.writeAll(response);
}

fn send_html_dashboard(stream: std.net.Stream) !void {
    const html = @embedFile("dashboard.html");
    var buf: [256]u8 = undefined;
    const response = try std.fmt.bufPrint(&buf, "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: {}\r\n\r\n", .{html.len});

    try stream.writeAll(response);
    try stream.writeAll(html);
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const lct_module = @import("lct.zig");
const LinkCutTree = lct_module.LinkCutTree;

pub const ServerStatus = enum {
    online,
    offline,
    degraded,

    pub fn format(self: ServerStatus, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        const str = switch (self) {
            .online => "ONLINE",
            .offline => "OFFLINE",
            .degraded => "DEGRADED",
        };
        try writer.writeAll(str);
    }
};

pub const Server = struct {
    id: u32,
    name: []const u8,
    status: ServerStatus,
    lct_node: *LinkCutTree.Node,

    pub fn init(id: u32, name: []const u8, status: ServerStatus, lct_node: *LinkCutTree.Node) Server {
        return Server{
            .id = id,
            .name = name,
            .status = status,
            .lct_node = lct_node,
        };
    }
};

pub const Network = struct {
    allocator: Allocator,
    lct: LinkCutTree,
    servers: std.ArrayList(Server),
    next_id: u32,
    links_count: u32,

    pub fn init(allocator: Allocator) Network {
        return Network{
            .allocator = allocator,
            .lct = LinkCutTree.init(allocator),
            .servers = std.ArrayList(Server).init(allocator),
            .next_id = 0,
            .links_count = 0,
        };
    }

    pub fn deinit(self: *Network) void {
        for (self.servers.items) |server| {
            self.lct.destroy_node(server.lct_node);
        }
        self.servers.deinit();
    }

    pub fn add_server(self: *Network, name: []const u8, status: ServerStatus) !*Server {
        const lct_node = try self.lct.create_node(@intCast(self.next_id));
        const server = Server.init(self.next_id, name, status, lct_node);
        try self.servers.append(server);
        self.next_id += 1;
        return &self.servers.items[self.servers.items.len - 1];
    }

    pub fn connect_servers(self: *Network, server_a: *Server, server_b: *Server) void {
        if (!self.lct.connected(server_a.lct_node, server_b.lct_node)) {
            self.lct.link(server_a.lct_node, server_b.lct_node);
            self.links_count += 1;
        }
    }

    pub fn disconnect_servers(self: *Network, server: *Server) void {
        self.lct.cut(server.lct_node);
        if (self.links_count > 0) {
            self.links_count -= 1;
        }
    }

    pub fn are_connected(self: *Network, server_a: *Server, server_b: *Server) bool {
        return self.lct.connected(server_a.lct_node, server_b.lct_node);
    }

    pub fn path_length(self: *Network, server_a: *Server, server_b: *Server) ?u32 {
        if (self.lct.path_size(server_a.lct_node, server_b.lct_node)) |size| {
            return size - 1; // Convert node count to edge count
        }
        return null;
    }

    pub fn find_network_root(self: *Network, server: *Server) u32 {
        const root_node = self.lct.find_root(server.lct_node);
        return @intCast(root_node.value);
    }

    pub fn get_server(self: *Network, id: u32) ?*Server {
        for (self.servers.items) |*server| {
            if (server.id == id) {
                return server;
            }
        }
        return null;
    }

    pub fn count_network_partitions(self: *Network) u32 {
        var partitions = std.AutoHashMap(u32, void).init(self.allocator);
        defer partitions.deinit();

        for (self.servers.items) |*server| {
            const root_id = self.find_network_root(server);
            partitions.put(root_id, {}) catch continue;
        }

        return @intCast(partitions.count());
    }

    pub fn set_server_status(self: *Network, server: *Server, status: ServerStatus) void {
        _ = self;
        server.status = status;
    }
};

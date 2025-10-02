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

pub const Link = struct {
    from: u32,
    to: u32,
    weight: f32,
};

pub const Network = struct {
    allocator: Allocator,
    lct: LinkCutTree,
    servers: std.ArrayList(Server),
    links: std.ArrayList(Link),
    next_id: u32,
    links_count: u32,

    pub fn init(allocator: Allocator) Network {
        return Network{
            .allocator = allocator,
            .lct = LinkCutTree.init(allocator),
            .servers = std.ArrayList(Server).init(allocator),
            .links = std.ArrayList(Link).init(allocator),
            .next_id = 0,
            .links_count = 0,
        };
    }

    pub fn deinit(self: *Network) void {
        for (self.servers.items) |server| {
            self.lct.destroy_node(server.lct_node);
        }
        self.servers.deinit();
        self.links.deinit();
    }

    pub fn add_server(self: *Network, name: []const u8, status: ServerStatus) !u32 {
        const lct_node = try self.lct.create_node(@intCast(self.next_id));
        const server = Server.init(self.next_id, name, status, lct_node);
        try self.servers.append(server);
        const id = self.next_id;
        self.next_id += 1;
        return id;
    }

    pub fn connect_servers(self: *Network, id_a: u32, id_b: u32) !void {
        const server_a = self.get_server(id_a) orelse return error.ServerNotFound;
        const server_b = self.get_server(id_b) orelse return error.ServerNotFound;

        if (!self.lct.connected(server_a.lct_node, server_b.lct_node)) {
            self.lct.link(server_a.lct_node, server_b.lct_node);

            // Add link with random weight (simulating flow)
            var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
            const random = prng.random();
            const weight = random.float(f32) * 10.0 + 0.5; // Random weight between 0.5 and 10.5

            try self.links.append(Link{
                .from = id_a,
                .to = id_b,
                .weight = weight,
            });
            self.links_count += 1;
        }
    }

    pub fn disconnect_server(self: *Network, id: u32) !void {
        const server = self.get_server(id) orelse return error.ServerNotFound;
        self.lct.cut(server.lct_node);

        // Remove all links involving this server
        var i: usize = 0;
        while (i < self.links.items.len) {
            const link = self.links.items[i];
            if (link.from == id or link.to == id) {
                _ = self.links.swapRemove(i);
                if (self.links_count > 0) {
                    self.links_count -= 1;
                }
            } else {
                i += 1;
            }
        }
    }

    pub fn are_connected(self: *Network, id_a: u32, id_b: u32) bool {
        const server_a = self.get_server(id_a) orelse return false;
        const server_b = self.get_server(id_b) orelse return false;
        return self.lct.connected(server_a.lct_node, server_b.lct_node);
    }

    pub fn path_length(self: *Network, id_a: u32, id_b: u32) ?u32 {
        const server_a = self.get_server(id_a) orelse return null;
        const server_b = self.get_server(id_b) orelse return null;

        if (self.lct.path_size(server_a.lct_node, server_b.lct_node)) |size| {
            return size - 1; // Convert node count to edge count
        }
        return null;
    }

    pub fn find_network_root(self: *Network, id: u32) ?u32 {
        const server = self.get_server(id) orelse return null;
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
            if (self.find_network_root(server.id)) |root_id| {
                partitions.put(root_id, {}) catch continue;
            }
        }

        return @intCast(partitions.count());
    }

    pub fn set_server_status(self: *Network, id: u32, status: ServerStatus) !void {
        const server = self.get_server(id) orelse return error.ServerNotFound;
        server.status = status;
    }
};

const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

pub const LinkCutTree = struct {
    allocator: Allocator,

    pub const Node = struct {
        value: i32,
        parent: ?*Node,
        left: ?*Node,
        right: ?*Node,
        path_parent: ?*Node,
        reversed: bool,
        size: u32,

        const Self = @This();

        pub fn init(value: i32) Self {
            return Self{
                .value = value,
                .parent = null,
                .left = null,
                .right = null,
                .path_parent = null,
                .reversed = false,
                .size = 1,
            };
        }

        pub fn is_root(self: *Self) bool {
            return self.parent == null or (self.parent.?.left != self and self.parent.?.right != self);
        }

        pub fn push(self: *Self) void {
            if (self.reversed) {
                const temp = self.left;
                self.left = self.right;
                self.right = temp;

                if (self.left) |left| {
                    left.reversed = !left.reversed;
                }
                if (self.right) |right| {
                    right.reversed = !right.reversed;
                }

                self.reversed = false;
            }
        }

        pub fn update(self: *Self) void {
            self.size = 1;
            if (self.left) |left| {
                self.size += left.size;
            }
            if (self.right) |right| {
                self.size += right.size;
            }
        }

        pub fn rotate(self: *Self) void {
            const parent = self.parent.?;
            const grand = parent.parent;

            if (parent.left == self) {
                parent.left = self.right;
                if (self.right) |right| {
                    right.parent = parent;
                }
                self.right = parent;
            } else {
                parent.right = self.left;
                if (self.left) |left| {
                    left.parent = parent;
                }
                self.left = parent;
            }

            parent.parent = self;
            self.parent = grand;

            if (grand) |g| {
                if (g.left == parent) {
                    g.left = self;
                } else if (g.right == parent) {
                    g.right = self;
                }
            }

            parent.update();
            self.update();
        }

        pub fn splay(self: *Self) void {
            self.push();

            while (!self.is_root()) {
                const parent = self.parent.?;

                if (!parent.is_root()) {
                    const grand = parent.parent.?;
                    grand.push();
                    parent.push();
                    self.push();

                    if ((grand.left == parent) == (parent.left == self)) {
                        parent.rotate();
                    } else {
                        self.rotate();
                    }
                } else {
                    parent.push();
                    self.push();
                }
                self.rotate();
            }
        }
    };

    pub fn init(allocator: Allocator) LinkCutTree {
        return LinkCutTree{
            .allocator = allocator,
        };
    }

    pub fn create_node(self: *LinkCutTree, value: i32) !*Node {
        const node = try self.allocator.create(Node);
        node.* = Node.init(value);
        return node;
    }

    pub fn destroy_node(self: *LinkCutTree, node: *Node) void {
        self.allocator.destroy(node);
    }

    pub fn access(self: *LinkCutTree, node: *Node) void {
        _ = self;
        var current: ?*Node = node;
        var last: ?*Node = null;

        while (current) |curr| {
            curr.splay();
            if (curr.right) |right| {
                right.path_parent = curr;
                right.parent = null;
            }
            curr.right = last;
            if (last) |l| {
                l.path_parent = null;
                l.parent = curr;
            }
            curr.update();
            last = curr;
            current = curr.path_parent;
        }

        node.splay();
    }

    pub fn make_root(self: *LinkCutTree, node: *Node) void {
        self.access(node);
        node.reversed = !node.reversed;
    }

    pub fn find_root(self: *LinkCutTree, node: *Node) *Node {
        self.access(node);
        var current = node;
        current.push();
        while (current.left) |left| {
            current = left;
            current.push();
        }
        current.splay();
        return current;
    }

    pub fn link(self: *LinkCutTree, child: *Node, parent: *Node) void {
        self.make_root(child);
        self.access(parent);
        child.path_parent = parent;
    }

    pub fn cut(self: *LinkCutTree, node: *Node) void {
        self.access(node);
        if (node.left) |left| {
            left.parent = null;
            node.left = null;
            node.update();
        }
    }

    pub fn connected(self: *LinkCutTree, a: *Node, b: *Node) bool {
        return self.find_root(a) == self.find_root(b);
    }

    pub fn lca(self: *LinkCutTree, a: *Node, b: *Node) ?*Node {
        if (!self.connected(a, b)) {
            return null;
        }

        self.access(a);
        self.access(b);

        a.splay();
        if (a.path_parent) |pp| {
            return pp;
        } else {
            return a;
        }
    }

    pub fn path_size(self: *LinkCutTree, from: *Node, to: *Node) ?u32 {
        if (!self.connected(from, to)) {
            return null;
        }

        self.make_root(from);
        self.access(to);
        return to.size;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lct = LinkCutTree.init(allocator);

    print("=== Link-Cut Tree Implementation Demo ===\n\n", .{});

    print("Creating nodes with values 1-10...\n", .{});
    var nodes: [10]*LinkCutTree.Node = undefined;
    for (0..10) |i| {
        nodes[i] = try lct.create_node(@intCast(i + 1));
        print("Created node {}\n", .{i + 1});
    }

    print("\nBuilding a tree structure:\n", .{});
    print("  Tree 1: 1-2-3-4-5 (linear chain)\n", .{});
    lct.link(nodes[1], nodes[0]);
    lct.link(nodes[2], nodes[1]);
    lct.link(nodes[3], nodes[2]);
    lct.link(nodes[4], nodes[3]);

    print("  Tree 2: 6-7-8 with 9 and 10 as children of 7\n", .{});
    lct.link(nodes[6], nodes[5]);
    lct.link(nodes[7], nodes[6]);
    lct.link(nodes[8], nodes[6]);
    lct.link(nodes[9], nodes[6]);

    print("\nTesting connectivity...\n", .{});
    print("Node 1 and Node 5 connected: {}\n", .{lct.connected(nodes[0], nodes[4])});
    print("Node 1 and Node 6 connected: {}\n", .{lct.connected(nodes[0], nodes[5])});
    print("Node 6 and Node 10 connected: {}\n", .{lct.connected(nodes[5], nodes[9])});

    print("\nFinding roots...\n", .{});
    print("Root of node 3: {}\n", .{lct.find_root(nodes[2]).value});
    print("Root of node 8: {}\n", .{lct.find_root(nodes[7]).value});

    print("\nTesting path sizes...\n", .{});
    if (lct.path_size(nodes[0], nodes[4])) |size| {
        print("Path size from node 1 to node 5: {}\n", .{size});
    }
    if (lct.path_size(nodes[5], nodes[9])) |size| {
        print("Path size from node 6 to node 10: {}\n", .{size});
    }

    print("\nTesting LCA (Lowest Common Ancestor)...\n", .{});
    if (lct.lca(nodes[1], nodes[3])) |ancestor| {
        print("LCA of nodes 2 and 4: {}\n", .{ancestor.value});
    }
    if (lct.lca(nodes[7], nodes[8])) |ancestor| {
        print("LCA of nodes 8 and 9: {}\n", .{ancestor.value});
    }

    print("\nLinking trees together...\n", .{});
    print("Connecting node 5 to node 6...\n", .{});
    lct.link(nodes[4], nodes[5]);

    print("Now testing connectivity after linking:\n", .{});
    print("Node 1 and Node 10 connected: {}\n", .{lct.connected(nodes[0], nodes[9])});

    if (lct.path_size(nodes[0], nodes[9])) |size| {
        print("Path size from node 1 to node 10: {}\n", .{size});
    }

    print("\nTesting cuts...\n", .{});
    print("Cutting node 3 from its parent...\n", .{});
    lct.cut(nodes[2]);

    print("After cut - Node 1 and Node 4 connected: {}\n", .{lct.connected(nodes[0], nodes[3])});
    print("After cut - Node 1 and Node 2 connected: {}\n", .{lct.connected(nodes[0], nodes[1])});

    print("\nTesting make_root operation...\n", .{});
    print("Making node 8 the root of its tree...\n", .{});
    lct.make_root(nodes[7]);
    print("New root of node 6: {}\n", .{lct.find_root(nodes[5]).value});

    print("\nPerforming additional operations...\n", .{});

    print("Testing more link operations:\n", .{});
    print("Root of node 1: {}\n", .{lct.find_root(nodes[0]).value});
    print("Root of node 6: {}\n", .{lct.find_root(nodes[5]).value});

    print("Creating a connection between separated trees...\n", .{});
    lct.link(nodes[0], nodes[5]);
    print("After linking node 1 to node 6:\n", .{});
    print("Node 1 and Node 10 connected: {}\n", .{lct.connected(nodes[0], nodes[9])});

    if (lct.path_size(nodes[0], nodes[9])) |size| {
        print("Path size from node 1 to node 10: {}\n", .{size});
    }

    print("Operations completed successfully!\n", .{});

    print("\nCleaning up...\n", .{});
    for (nodes) |node| {
        lct.destroy_node(node);
    }

    print("Demo completed successfully!\n", .{});
}
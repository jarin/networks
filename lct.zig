const std = @import("std");
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

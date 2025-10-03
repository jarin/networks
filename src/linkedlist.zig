const std = @import("std");

pub fn SkipList(comptime T: type) type {
    return struct {
        gpa: std.mem.Allocator,
        rng: std.rand.Random,
        lt: *const fn (a: T, b: T) bool,
        max_levels: usize,
        levels: usize,
        head: ?*Node,

        const Node = struct {
            value: T,
            next: ?*Node,
            down: ?*Node,
        };

        // Create new node helper
        fn createNode(self: *Self, value: T, next: ?*Node, down: ?*Node) !*Node {
            var node = try self.gpa.create(Node);
            node.* = Node{ .value = value, .next = next, .down = down };
            return node;
        }

        // Insert (basic, simplified for demonstration)
        pub fn insert(self: *Self, value: T) !void {
            var update = std.ArrayList(?*Node).init(self.gpa);
            for (self.levels) |_| {
                try update.append(null);
            }
            var current = self.head;
            var lvl: isize = @intCast(isize, self.levels - 1);

            // Traverse levels to find the insert position
            while (lvl >= 0) : (lvl -= 1) {
                while (current != null and current.?.next != null and self.lt(current.?.next.?.value, value)) {
                    current = current.?.next;
                }
                update.items[@intCast(usize, lvl)] = current;
                if (lvl > 0 and current != null) {
                    current = current.?.down;
                }
            }

            // Insert new node at base
            var new_node = try self.createNode(value, null, null);
            if (update.items[0] == null) {
                self.head = new_node;
            } else {
                new_node.next = update.items[0].?.next;
                update.items[0].?.next = new_node;
            }

            // Randomly add higher levels
            var lvl_inserted: usize = 1;
            while (lvl_inserted < self.max_levels and self.rng.boolean()) : (lvl_inserted += 1) {
                var upper_node = try self.createNode(value, null, new_node);
                if (update.items[lvl_inserted] == null) {
                    self.head = upper_node;
                } else {
                    upper_node.next = update.items[lvl_inserted].?.next;
                    update.items[lvl_inserted].?.next = upper_node;
                }
                new_node = upper_node;
            }

            update.deinit();
        }

        // Search (basic)
        pub fn search(self: *Self, value: T) bool {
            var current = self.head;
            var lvl: usize = self.levels;
            while (lvl > 0) {
                while (current != null and current.?.next != null and self.lt(current.?.next.?.value, value)) {
                    current = current.?.next;
                }
                if (current != null and current.?.next != null and current.?.next.?.value == value) {
                    return true;
                }
                lvl -= 1;
                if (current != null) {
                    current = current.?.down;
                }
            }
            return false;
        }
    };
}
fn cmp(a: i32, b: i32) bool {
    return a < b;
}

// Main routine
pub fn main() !void {
    var allocator = std.heap.page_allocator;
    var prng = std.rand.DefaultPrng.init(42);

    // Comparison function for integers (ascending)
    var skiplist = SkipList(i32){
        .gpa = allocator,
        .rng = prng.random(),
        .lt = &cmp,
        .max_levels = 4,
        .levels = 4,
        .head = null,
    };

    try skiplist.insert(10);
    try skiplist.insert(30);
    try skiplist.insert(20);
    try skiplist.insert(40);

    std.debug.print("Searching for 30: {}\n", .{skiplist.search(30)});
    std.debug.print("Searching for 99: {}\n", .{skiplist.search(99)});
}

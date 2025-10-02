const std = @import("std");
const print = std.debug.print;
const lct_module = @import("lct.zig");
const LinkCutTree = lct_module.LinkCutTree;

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

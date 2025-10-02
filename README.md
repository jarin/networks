# Dynamic Network Connectivity Monitor

A real-time network connectivity monitoring system built with Zig and visualized using D3.js. This project demonstrates the use of Link-Cut Trees for efficient dynamic connectivity queries in a network topology.

## Features

### Core Data Structure
- **Link-Cut Tree**: O(log n) amortized dynamic connectivity
- Splay tree-based implementation with lazy propagation
- Path aggregation and LCA queries
- Dynamic link/cut operations

### Network Management
- Add/remove servers dynamically
- Track server status (online, degraded, offline)
- Connect/disconnect servers
- Real-time connectivity queries
- Network partition detection
- Path length calculations

### Visualization
- Interactive D3.js force-directed graph
- Real-time network topology updates
- Drag-and-drop node repositioning
- Color-coded server status
- Network statistics dashboard
- Auto-refresh every 5 seconds

## Architecture

```
├── lct.zig           - Link-Cut Tree implementation
├── network.zig       - Network connectivity layer
├── server.zig        - HTTP API server
├── dashboard.html    - D3.js visualization frontend
└── demo.zig          - Basic LCT demonstration
```

## API Endpoints

### GET `/api/network`
Returns the full network state with nodes and links in D3.js-compatible format.

**Response:**
```json
{
  "nodes": [
    {"id": 0, "name": "web-1", "status": "online", "group": 0}
  ],
  "links": [
    {"source": 0, "target": 1}
  ]
}
```

### GET `/api/stats`
Returns network statistics.

**Response:**
```json
{
  "servers": 5,
  "links": 4,
  "partitions": 1,
  "online": 4,
  "offline": 0,
  "degraded": 1
}
```

### POST `/api/server`
Add a new server to the network.

**Request:**
```json
{
  "name": "web-3",
  "status": "online"
}
```

### POST `/api/link`
Connect two servers.

**Request:**
```json
{
  "from": 0,
  "to": 1
}
```

### POST `/api/disconnect`
Disconnect a server from its parent.

**Request:**
```json
{
  "server": 2
}
```

## Usage

### Run the Basic Demo
```bash
zig run demo.zig
```

### Run the Network Monitor Server
```bash
zig build-exe server.zig
./server
```

Then open your browser to `http://127.0.0.1:8080`

## Use Cases

1. **Network Topology Monitoring**: Track data center connectivity in real-time
2. **Partition Detection**: Identify network splits and isolated components
3. **Path Analysis**: Find communication paths between servers
4. **Capacity Planning**: Visualize network structure for optimization
5. **Failure Simulation**: Test network resilience by disconnecting nodes

## Link-Cut Tree Operations

- **access(node)**: Makes the path from root to node a preferred path
- **link(child, parent)**: Connects two trees
- **cut(node)**: Removes edge between node and its parent
- **find_root(node)**: Returns the root of the tree containing node
- **connected(a, b)**: Checks if two nodes are in the same tree
- **lca(a, b)**: Finds lowest common ancestor
- **path_size(from, to)**: Returns number of nodes on path

## Performance

All operations have **O(log n) amortized** time complexity through splay tree rotations.

## Implementation Details

The Link-Cut Tree maintains a forest of trees where:
- Each tree is represented as a set of preferred paths
- Preferred paths are stored as splay trees
- Path parent pointers connect different splay trees
- Lazy reversal flags support efficient re-rooting

## License

This is a demonstration project for educational purposes.

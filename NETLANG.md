# NetLang - Network Algorithm Language

NetLang is a simple domain-specific language for implementing and visualizing graph/network algorithms.

## Language Features

### Data Types
- **number**: Integers and floats (e.g., `42`, `3.14`, `-5`)
- **string**: Text literals (e.g., `"hello"`)
- **boolean**: `true` or `false`
- **null**: Represents no value
- **array**: Ordered list (e.g., `[1, 2, 3]`)
- **set**: Unordered unique collection (e.g., `{1, 2, 3}`)
- **map**: Key-value pairs (e.g., `{a: 1, b: 2}`)
- **queue**: FIFO data structure
- **priority_queue**: Min-heap priority queue

### Variables

```
let x = 10
let name = "Alice"
let visited = set()          // Empty set
let distances = {}           // Empty map (for use with put/get)
let initial_dist = {0: 0}    // Map with initial values
```

**Note:** Empty `{}` creates a map. For empty sets, use `set()` function.

### Control Flow

**If Statement:**
```
if condition {
    // statements
} else if other_condition {
    // statements
} else {
    // statements
}
```

**While Loop:**
```
while condition {
    // statements
}
```

**For Loop:**
```
for item in collection {
    // statements
}

for i in range(0, 10) {
    // statements
}
```

### Operators

**Arithmetic:** `+`, `-`, `*`, `/`, `%`
**Comparison:** `==`, `!=`, `<`, `>`, `<=`, `>=`
**Logical:** `and`, `or`, `not`

### Graph Primitives

#### Node Operations
- `nodes()` - Returns array of all node IDs
- `node_count()` - Returns number of nodes
- `node_exists(id)` - Check if node exists

#### Edge Operations
- `neighbors(node_id)` - Returns array of neighbor node IDs
- `edges()` - Returns array of all edges `[{from, to, weight}, ...]`
- `edge_exists(from, to)` - Check if edge exists
- `weight(from, to)` - Get edge weight (returns `null` if no edge)
- `set_weight(from, to, value)` - Set edge weight

#### Visualization
- `highlight_node(id, color)` - Highlight a node
  - Colors: `"visiting"` (yellow), `"visited"` (green), `"current"` (red), `"path"` (blue)
- `highlight_edge(from, to, color)` - Highlight an edge
  - Colors: `"active"` (green), `"path"` (blue), `"relaxed"` (orange)
- `clear_highlights()` - Clear all highlights
- `set_node_label(id, text)` - Set node label text
- `set_edge_label(from, to, text)` - Set edge label text
- `log(message)` - Output message to console
- `sleep(milliseconds)` - Pause execution for visualization

### Built-in Functions

#### Data Structure Operations
- `array()` - Create empty array
- `set()` - Create empty set
- `map()` - Create empty map
- `queue()` - Create empty queue
- `priority_queue()` - Create empty priority queue

- `push(array, item)` - Add to end of array
- `pop(array)` - Remove and return last item
- `add(set, item)` - Add to set
- `has(collection, item)` - Check membership
- `get(map, key)` - Get value from map
- `put(map, key, value)` - Set value in map
- `size(collection)` - Get size
- `enqueue(queue, item)` - Add to queue
- `dequeue(queue)` - Remove and return from queue
- `pq_insert(pq, item, priority)` - Insert with priority
- `pq_extract_min(pq)` - Extract minimum priority item
- `is_empty(collection)` - Check if empty

#### Utility Functions
- `min(a, b)` - Return minimum
- `max(a, b)` - Return maximum
- `abs(x)` - Absolute value
- `range(start, end)` - Generate range array
- `len(collection)` - Get length

## Example Algorithms

### 1. Breadth-First Search (BFS)

```
// BFS from source to find shortest paths
let source = 0
let visited = set()
let distances = {0: 0}
let q = queue()

enqueue(q, source)
add(visited, source)
highlight_node(source, "current")
sleep(500)

while not is_empty(q) {
    let current = dequeue(q)
    highlight_node(current, "visiting")
    log("Visiting node " + current)
    sleep(300)

    for neighbor in neighbors(current) {
        if not has(visited, neighbor) {
            add(visited, neighbor)
            put(distances, neighbor, get(distances, current) + 1)
            enqueue(q, neighbor)
            highlight_edge(current, neighbor, "active")
            set_node_label(neighbor, "d=" + get(distances, neighbor))
            sleep(200)
        }
    }

    highlight_node(current, "visited")
}

log("BFS complete!")
```

### 2. Depth-First Search (DFS)

```
// DFS traversal using recursion
let visited = set()

function dfs(node) {
    add(visited, node)
    highlight_node(node, "current")
    log("Visiting: " + node)
    sleep(300)

    for neighbor in neighbors(node) {
        if not has(visited, neighbor) {
            highlight_edge(node, neighbor, "active")
            sleep(200)
            dfs(neighbor)
        }
    }

    highlight_node(node, "visited")
}

dfs(0)
log("DFS complete!")
```

### 3. Dijkstra's Shortest Path

```
// Dijkstra's algorithm from source
let source = 0
let dist = {}
let visited = {}
let pq = priority_queue()

// Initialize distances
for node in nodes() {
    if node == source {
        put(dist, node, 0)
    } else {
        put(dist, node, 999999)
    }
}

pq_insert(pq, source, 0)
highlight_node(source, "current")

while not is_empty(pq) {
    let u = pq_extract_min(pq)

    if has(visited, u) {
        continue
    }

    add(visited, u)
    highlight_node(u, "visiting")
    set_node_label(u, "d=" + get(dist, u))
    log("Current: " + u + " (dist=" + get(dist, u) + ")")
    sleep(500)

    for v in neighbors(u) {
        let w = weight(u, v)
        let new_dist = get(dist, u) + w

        if new_dist < get(dist, v) {
            put(dist, v, new_dist)
            pq_insert(pq, v, new_dist)
            highlight_edge(u, v, "relaxed")
            set_edge_label(u, v, "relax")
            log("  Relaxed edge " + u + " -> " + v + ": " + new_dist)
            sleep(300)
        }
    }

    highlight_node(u, "visited")
}

log("Dijkstra complete!")
```

### 4. Bellman-Ford (Negative Weights)

```
// Bellman-Ford algorithm - handles negative weights
let source = 0
let dist = {}

// Initialize
for node in nodes() {
    if node == source {
        put(dist, node, 0)
    } else {
        put(dist, node, 999999)
    }
}

let n = node_count()

// Relax edges V-1 times
for i in range(0, n - 1) {
    log("Iteration " + i)
    let updated = false

    for edge in edges() {
        let u = edge.from
        let v = edge.to
        let w = edge.weight

        if get(dist, u) + w < get(dist, v) {
            put(dist, v, get(dist, u) + w)
            highlight_edge(u, v, "relaxed")
            set_node_label(v, "d=" + get(dist, v))
            updated = true
            sleep(200)
        }
    }

    if not updated {
        break
    }
}

// Check for negative cycles
for edge in edges() {
    let u = edge.from
    let v = edge.to
    let w = edge.weight

    if get(dist, u) + w < get(dist, v) {
        log("Negative cycle detected!")
        highlight_edge(u, v, "path")
    }
}

log("Bellman-Ford complete!")
```

### 5. Finding Connected Components

```
// Find all connected components
let visited = set()
let component = {}
let comp_id = 0

function explore(node, id) {
    add(visited, node)
    put(component, node, id)
    highlight_node(node, "visiting")
    set_node_label(node, "C" + id)
    sleep(200)

    for neighbor in neighbors(node) {
        if not has(visited, neighbor) {
            highlight_edge(node, neighbor, "active")
            explore(neighbor, id)
        }
    }
}

for node in nodes() {
    if not has(visited, node) {
        log("Component " + comp_id)
        explore(node, comp_id)
        comp_id = comp_id + 1
        sleep(500)
    }
}

log("Found " + comp_id + " components")
```

### 6. Topological Sort (DAG)

```
// Topological sort using DFS
let visited = set()
let stack = array()

function topo_dfs(node) {
    add(visited, node)
    highlight_node(node, "visiting")
    sleep(200)

    for neighbor in neighbors(node) {
        if not has(visited, neighbor) {
            highlight_edge(node, neighbor, "active")
            topo_dfs(neighbor)
        }
    }

    push(stack, node)
    highlight_node(node, "visited")
}

for node in nodes() {
    if not has(visited, node) {
        topo_dfs(node)
    }
}

// Stack now contains topological order (reversed)
log("Topological order:")
for node in stack {
    log(node)
}
```

## Language Implementation Notes

- **Execution Model**: Interpreted with async execution for visualization pauses
- **Type System**: Dynamic typing with runtime type checking
- **Scoping**: Lexical scoping with function closures
- **Error Handling**: Runtime errors stop execution and display error message
- **Performance**: Optimized for readability over performance
- **Visualization**: All highlight/sleep operations are asynchronous and queued

## Future Extensions

- Pattern matching
- First-class functions and lambdas
- Import/export system for algorithm libraries
- Custom data structure definitions
- Debugging breakpoints
- Step-by-step execution mode

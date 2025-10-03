# NetLang - Network Algorithm Visualization Language

NetLang is a domain-specific language for implementing and visualizing graph/network algorithms with real-time visual feedback. Built with TypeScript for the interpreter and Zig for the backend server.

## Features

### Language & Interpreter
- **Complete DSL**: Custom language with lexer, parser, and async interpreter
- **TypeScript implementation**: Type-safe interpreter prevents falsy value bugs
- **Rich data structures**: Sets, maps, queues, priority queues, arrays
- **Control flow**: if/else, while, for, functions, recursion
- **Infinite loop protection**: Automatic timeout and iteration limits

### Algorithm Visualization
- **Real-time execution**: Watch algorithms run step-by-step with configurable delays
- **Graph primitives**: neighbors(), nodes(), edges(), weight()
- **Visualization API**: highlight_node(), highlight_edge(), set labels
- **Built-in examples**: BFS, DFS, Dijkstra, Connected Components

### Network Building
- **Dynamic networks**: Create networks with adjustable connectivity (sparse to dense)
- **Weight-based layout**: Nodes arrange based on edge weights and capacity
- **Interactive editing**: Add nodes/edges manually or generate random networks
- **Force simulation**: D3.js physics-based automatic layout

## Quick Start

### Prerequisites
- Zig compiler
- Node.js and npm (for TypeScript compilation)

### Building

1. Install dependencies:
```bash
npm install
```

2. Build TypeScript:
```bash
npm run build
```

3. Run the server:
```bash
zig run server.zig
```

4. Open browser to http://127.0.0.1:8080

## Project Structure

```
├── src/
│   └── netlang.ts       # TypeScript source (lexer, parser, interpreter)
├── dist/
│   ├── netlang.js       # Compiled JavaScript
│   └── netlang.d.ts     # TypeScript definitions
├── dashboard.html       # Main UI with D3.js visualization
├── server.zig          # HTTP API server
├── network.zig         # Network data structure with Link-Cut Tree
├── NETLANG.md          # Language specification
└── IMPROVEMENTS.md     # Roadmap and enhancement ideas
```

## NetLang Example

### Breadth-First Search

```netlang
let source = 0
let visited = set()
let q = queue()

enqueue(q, source)
add(visited, source)
highlight_node(source, "current")

while not is_empty(q) {
    let current = dequeue(q)
    highlight_node(current, "visiting")
    log("Visiting node " + current)

    for neighbor in neighbors(current) {
        if not has(visited, neighbor) {
            add(visited, neighbor)
            enqueue(q, neighbor)
            highlight_edge(current, neighbor, "active")
            sleep(50)
        }
    }

    highlight_node(current, "visited")
}

log("BFS complete!")
```

See [NETLANG.md](NETLANG.md) for full language specification and more examples.

## Development

### TypeScript Development

Watch mode for automatic recompilation:
```bash
npm run watch
```

Clean build artifacts:
```bash
npm run clean
```

## TypeScript Migration Benefits

The migration to TypeScript provides:

- **Type safety**: Eliminates falsy value bugs (e.g., node ID 0 being treated as false)
- **Better IDE support**: Auto-completion, refactoring, and inline documentation
- **Compile-time error detection**: Catch bugs before runtime
- **Self-documenting code**: Type annotations make the API clear

### Key Interfaces

```typescript
interface GraphAPI {
    nodes(): number[];
    neighbors(id: number): number[];
    weight(from: number, to: number): number | null;
    highlightNode(id: number, color: string): void;
    highlightEdge(from: number, to: number, color: string): void;
    log(message: string): void;
    sleep(ms: number): Promise<void>;
}
```

## Roadmap

See [IMPROVEMENTS.md](IMPROVEMENTS.md) for:
- 10+ prioritized enhancement recommendations
- TypeScript migration analysis
- New feature ideas (algorithm library, debugger, code editor, etc.)
- Priority ranking by impact and effort

Top priorities:
1. ✅ TypeScript migration (completed)
2. Enhanced error reporting with line context
3. Monaco/CodeMirror code editor integration
4. Graph import/export (GraphML, DOT, JSON)
5. Performance metrics and analytics

## License

MIT - Educational demonstration project

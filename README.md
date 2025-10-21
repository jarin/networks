# NetLang - Network Algorithm Visualization Language
experiment, for learning zig and link-cut trees. It may also be purty slop. I don't know yet.

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

3. Build and run the server:
```bash
# Using mise (recommended)
mise run dev

# Or manually (note: -mcpu=baseline ensures compatibility)
zig build-exe server.zig -O ReleaseFast -mcpu=baseline && ./server
```

4. Open browser to http://localhost:8080

### Using mise Tasks

```bash
mise run build          # Build Zig server (release)
mise run dev            # Build and run (development)
mise run docker:build   # Build Docker image
mise run docker:run     # Run Docker container
mise run all            # Build everything
```

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

## Production Deployment

### Docker

```bash
# Build Docker image
docker build -t netlang:latest .

# Run container
docker run -p 8080:8080 netlang:latest
```

### Health Endpoints

- `GET /health` - Liveness probe (returns node count and status)
- `GET /ready` - Readiness probe

### Deployment Platforms

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed guides:

- **DigitalOcean App Platform** - $5/month, fully managed
- **DigitalOcean Droplet** - $6/month, VPS with more control
- **Hetzner Cloud** - €4.15/month, best price/performance

### GitHub Actions

Automatic Docker builds and security scanning on every push to `main`:
- Pushes to GitHub Container Registry (`ghcr.io`)
- Multi-arch support (amd64/arm64)
- Trivy security scanning

## API Endpoints

### Network Management
- `GET /api/network` - Get full network state
- `GET /api/stats` - Network statistics
- `POST /api/server` - Add a node
- `POST /api/link` - Create an edge
- `POST /api/bulk-add` - Add multiple nodes
- `POST /api/bulk-link` - Create multiple edges (bulk)
- `POST /api/clear` - Clear the network

### Health & Monitoring
- `GET /health` - Liveness probe
- `GET /ready` - Readiness probe

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

Recent completions:
1. ✅ TypeScript migration
2. ✅ Enhanced error reporting (line context, "Did you mean?" suggestions)
3. ✅ Bulk API endpoints for performance
4. ✅ Docker & CI/CD ready

Next priorities:
1. Monaco/CodeMirror code editor integration
2. Graph import/export (GraphML, DOT, JSON)
3. Performance metrics and analytics
4. Step-by-step debugger

## Troubleshooting

### "Illegal hardware instruction" error

If you get this error when running the server:
```
illegal hardware instruction  zig run server.zig
```

**Cause 1**: Stack overflow from large buffer allocation in ReleaseFast mode.
**Cause 2**: CPU architecture mismatch.

**Solution**:
```bash
# Clean rebuild with correct settings
rm -f server
zig build-exe server.zig -O ReleaseFast -mcpu=baseline
./server
```

Or use mise (already configured correctly):
```bash
mise run build
mise run run
```

**Note**: If you still have issues, check `server.zig` line 42 - the buffer should be `[262144]u8` (256KB), not larger. Stack-allocated buffers >1MB can cause crashes with optimizations enabled.

### "Lexer is not defined" in browser

**Cause**: Browser can't find the global Lexer class.

**Solution**: The dist/netlang.js should have browser exports. Rebuild:
```bash
npm run build
cp netlang.js dist/netlang.js  # Ensure enhanced version is used
zig build-exe server.zig -O ReleaseFast -mcpu=baseline
```

### Large networks only partially connected

**Cause**: Server buffer too small for bulk operations.

**Solution**: Already fixed - server has 256KB buffer. Just restart:
```bash
./server
```

## License

MIT - Educational demonstration project

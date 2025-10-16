# Multi-stage build for NetLang Server
# Stage 1: Build the Zig application
FROM debian:bookworm-slim AS builder

# Install Zig
RUN apt-get update && apt-get install -y \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download and install Zig 0.13.0 (adjust version as needed)
RUN wget https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz && \
    tar -xf zig-linux-x86_64-0.13.0.tar.xz && \
    mv zig-linux-x86_64-0.13.0 /usr/local/zig && \
    ln -s /usr/local/zig/zig /usr/local/bin/zig && \
    rm zig-linux-x86_64-0.13.0.tar.xz

# Set working directory
WORKDIR /app

# Copy source files
COPY server.zig network.zig dashboard.html ./
COPY dist/ ./dist/

# Build the application with baseline CPU target for maximum compatibility
RUN zig build-exe server.zig -O ReleaseFast -mcpu=baseline

# Stage 2: Create minimal runtime image
FROM debian:bookworm-slim

# Install only runtime dependencies (if any)
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 netlang

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/server /app/server

# Copy static files (embedded in binary, but good to have for reference)
COPY dashboard.html ./
COPY dist/ ./dist/

# Change ownership
RUN chown -R netlang:netlang /app

# Switch to non-root user
USER netlang

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/usr/bin/curl", "-f", "http://localhost:8080/health", "||", "exit", "1"]

# Run the server
CMD ["/app/server"]

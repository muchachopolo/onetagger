FROM node:20 AS ui-builder

WORKDIR /app
COPY client/package.json client/pnpm-lock.yaml ./client/
RUN npm install -g pnpm
RUN cd client && pnpm install

COPY client ./client
RUN cd client && pnpm run build

FROM rust:1.75 AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    lld \
    autogen \
    libasound2-dev \
    pkg-config \
    make \
    libssl-dev \
    gcc \
    g++ \
    curl \
    wget \
    git \
    libwebkit2gtk-4.1-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . .
COPY --from=ui-builder /app/client/dist ./client/dist

RUN cargo build --release

FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libssl3 \
    ca-certificates \
    libwebkit2gtk-4.1-0 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/onetagger /app/onetagger

EXPOSE 8080

CMD ["./onetagger"]

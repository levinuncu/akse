# Stage 1: Build
FROM node:20-alpine AS builder

# Install pnpm
RUN npm install -g pnpm

# Set working directory
WORKDIR /app

# Copy only package files first for caching
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile --prod

# Copy source files
COPY . .

# Build the NestJS app
RUN pnpm run build

# Stage 2: Production image
FROM node:20-alpine

# Install pnpm (needed to run the app if scripts rely on it)
RUN npm install -g pnpm

WORKDIR /app

# Copy only production dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod

# Copy built files from builder
COPY --from=builder /app/dist ./dist


EXPOSE 3000

# Start the app
CMD ["node", "dist/main.js"]
# Frontend Dockerfile
FROM node:18-alpine as builder

WORKDIR /app

# Install curl for health checks
RUN apk add --no-cache curl

# Accept build argument for API URL
ARG VITE_API_BASE_URL=http://localhost:8000

# Copy package files
COPY package*.json ./

# Install dependencies (including dev dependencies for build)
RUN npm ci

# Copy source code
COPY . .

# Fix permissions for node_modules
RUN chmod -R 755 node_modules/.bin

# Set environment variable for build
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

# Build the application with explicit paths
RUN npx tsc && npx vite build

# Production stage
FROM nginx:alpine

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

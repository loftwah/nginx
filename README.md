# Custom NGINX Reverse Proxy

A lightweight, configurable NGINX reverse proxy with JSON logging, health checks, and dynamic upstream configuration. Built for container environments like ECS.

## Key Features

- JSON-formatted logging for better observability
- Built-in health check endpoint (`/health`)
- Dynamic upstream configuration via environment variables
- WebSocket support (configured for Rails/ActionCable)
- Gzip compression for common file types
- Optimized buffer settings for large headers/cookies
- Multi-architecture support (amd64/arm64)

## Quick Start

```bash
# Start the proxy and demo backend
docker compose up

# Test the proxy
curl -i http://localhost:42069/
curl -i http://localhost:42069/health

# View JSON-formatted logs
docker compose logs reverse-proxy
```

## Configuration

### Environment Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `UPSTREAM_HOST` | Yes | Backend service hostname/IP | - |
| `UPSTREAM_PORT` | Yes | Backend service port | - |

### NGINX Settings

- Maximum upload size: 10MB
- Gzip compression: Enabled for text/plain, CSS, JSON, JavaScript, XML
- Connection timeouts: 60s (connect, read, send)
- Header buffer size: 32k

## Development

Build locally:
```bash
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t reverse-proxy .
```

## Deployment

### To Amazon ECR

```bash
# Login to ECR
aws ecr get-login-password --region <region> | \
  docker login --username AWS --password-stdin <account_id>.dkr.ecr.<region>.amazonaws.com

# Build and push
docker buildx build --platform linux/amd64,linux/arm64 \
  -t <account_id>.dkr.ecr.<region>.amazonaws.com/reverse-proxy:latest \
  --push .
```

### ECS Task Definition Example

```json
{
  "containerDefinitions": [{
    "name": "reverse-proxy",
    "image": "<account_id>.dkr.ecr.<region>.amazonaws.com/reverse-proxy:latest",
    "environment": [
      {
        "name": "UPSTREAM_HOST",
        "value": "your-backend-service"
      },
      {
        "name": "UPSTREAM_PORT",
        "value": "3000"
      }
    ],
    "portMappings": [{
      "containerPort": 80,
      "protocol": "tcp"
    }]
  }]
}
```

## Troubleshooting

### Common Issues

1. **502 Bad Gateway**
   - Check if UPSTREAM_HOST and UPSTREAM_PORT are correct
   - Verify backend service is running
   - Check network connectivity

2. **400 Request Header Too Large**
   - Request headers exceed 32k buffer
   - Review cookie size and custom headers

3. **413 Request Entity Too Large**
   - Upload exceeds 10MB limit
   - Adjust client_max_body_size if needed

### Debugging Commands

```bash
# Verify NGINX configuration
docker compose exec reverse-proxy nginx -T

# Monitor logs
docker compose logs -f reverse-proxy

# Test health endpoint
curl -i http://localhost:42069/health
```

## Logging

The proxy outputs structured JSON logs with the following fields:
```json
{
  "timestamp": "2024-02-07T12:00:00+00:00",
  "remote_addr": "client.ip.address",
  "request": "GET /path HTTP/1.1",
  "status": "200",
  "bytes_sent": "1234",
  "request_time": "0.123",
  "http_referrer": "referrer_url",
  "http_user_agent": "user_agent_string"
}
```

## License

[License information here]

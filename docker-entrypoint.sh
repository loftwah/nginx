#!/bin/bash
set -e

# Substitute environment variables in the template
envsubst '${UPSTREAM_HOST} ${UPSTREAM_PORT}' < /etc/nginx/templates/nginx.template > /etc/nginx/conf.d/default.conf

# Execute the passed command (default is NGINX)
exec "$@"
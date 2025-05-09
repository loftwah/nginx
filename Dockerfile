FROM public.ecr.aws/nginx/nginx:1.28.0


# Install envsubst for environment variable substitution
RUN apt-get update && apt-get install -y gettext-base && apt-get clean

# Add the template configuration file
COPY nginx.template /etc/nginx/templates/nginx.template

# Add the entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]

# Default command
CMD ["nginx", "-g", "daemon off;"]

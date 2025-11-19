# Use Ruby 3.2 Alpine for small image size
FROM ruby:3.2-alpine

# Install system dependencies
RUN apk add --no-cache \
    postgresql-dev \
    postgresql-client \
    build-base \
    nodejs \
    tzdata \
    git \
    yaml-dev \
    bash \
    sudo

# Create user matching host user (default to 1000:1000)
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN addgroup -g ${GROUP_ID} appuser && \
    adduser -D -u ${USER_ID} -G appuser appuser && \
    echo 'appuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set working directory
WORKDIR /app

# Change ownership
RUN chown -R appuser:appuser /app

# Copy gemspec and Gemfile for dependency resolution
COPY --chown=appuser:appuser better_structure_sql.gemspec ./
COPY --chown=appuser:appuser Gemfile* ./
COPY --chown=appuser:appuser lib/better_structure_sql/version.rb ./lib/better_structure_sql/

# Switch to appuser for bundle install
USER appuser

# Install gem dependencies
RUN bundle install

# Switch back to root for copying files
USER root

# Copy the entire gem source
COPY --chown=appuser:appuser . .

# Switch to integration app directory
WORKDIR /app/integration

# Copy integration app Gemfile
COPY --chown=appuser:appuser integration/Gemfile* ./

# Switch to appuser for bundle install
USER appuser

# Install Rails app dependencies
RUN bundle install

# Switch back to root for final setup
USER root

# Copy the rest of the integration app
COPY --chown=appuser:appuser integration ./

# Expose port 3000
EXPOSE 3000

# Set Rails environment
ENV RAILS_ENV=development

# Entrypoint script
COPY docker-entrypoint.sh /usr/bin/
RUN chmod 755 /usr/bin/docker-entrypoint.sh

# Switch to appuser for running the application
USER appuser

ENTRYPOINT ["docker-entrypoint.sh"]

# Default command (can be overridden by docker-compose.yml)
CMD ["bash", "-c", "rails server -b 0.0.0.0"]

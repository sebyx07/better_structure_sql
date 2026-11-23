# Dev image for the integration app (integration/) — see DOCKER.md.
# Ruby matches .ruby-version; bump both together.
FROM ruby:4.0.10-alpine

# Build tools and client libraries for the native gems (pg, sqlite3, nokogiri, psych, puma)
RUN apk add --no-cache \
    postgresql-dev \
    postgresql-client \
    sqlite-dev \
    build-base \
    nodejs \
    tzdata \
    git \
    yaml-dev \
    bash \
    sudo

# Create user matching host user (default to 1000:1000) so files written to the
# mounted checkout keep the host user's ownership
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN addgroup -g ${GROUP_ID} appuser && \
    adduser -D -u ${USER_ID} -G appuser appuser && \
    echo 'appuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /app
RUN chown -R appuser:appuser /app /usr/local/bundle

# The integration app depends on the gem by path (`path: '..'`), so its bundle
# needs the gemspec and version file in place. Copied first to keep the gem layer cached.
COPY --chown=appuser:appuser better_structure_sql.gemspec ./
COPY --chown=appuser:appuser lib/better_structure_sql/version.rb ./lib/better_structure_sql/
COPY --chown=appuser:appuser integration/Gemfile integration/Gemfile.lock ./integration/

WORKDIR /app/integration
USER appuser
RUN bundle install

# The rest of the source. docker-compose.yml mounts the checkout over /app, so this
# copy only matters when the image runs without the mount.
USER root
COPY --chown=appuser:appuser . /app

COPY docker-entrypoint.sh /usr/bin/
RUN chmod 755 /usr/bin/docker-entrypoint.sh

EXPOSE 3000
ENV RAILS_ENV=development

USER appuser
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command (docker-compose.yml overrides it)
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

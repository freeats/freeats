# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.3
FROM ruby:$RUBY_VERSION-slim AS base

ARG NODE_VERSION=22.7.0
ARG YARN_VERSION=1.22.22
ARG PACKAGES="python-is-python3 libvips"

ARG NODE_ENV=development

ENV NODE_ENV=${NODE_ENV}

ENV BUNDLE_PATH="/usr/local/bundle"

# Rails app lives here
WORKDIR /rails

# Install packages needed to build gems and Node modules
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential curl node-gyp pkg-config git \
    libjemalloc2 libpq-dev postgresql-client \
    $PACKAGES

# Install JavaScript dependencies
ENV PATH=/rails/bin:/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master

# Install bundler
COPY .ruby-version Gemfile Gemfile.lock ./
RUN gem install -N bundler:$(awk '/BUNDLED WITH/{getline; print $1}' Gemfile.lock)

# Install application gems
RUN bundle install

RUN gem install foreman

# # Install Node modules
COPY --link package.json yarn.lock .npmrc ./
RUN yarn install --verbose

# Copy application code
COPY --link . .

RUN git config --global --add safe.directory /rails

# Entrypoint prepares the database
ENTRYPOINT ["./bin/docker-entrypoint-development"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/dev"]

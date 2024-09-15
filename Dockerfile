# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.3.3
FROM ruby:$RUBY_VERSION-slim AS base

ARG RAILS_ENV=production
ARG NODE_ENV=production
ARG CI

ENV RAILS_ENV=${RAILS_ENV}
ENV NODE_ENV=${NODE_ENV}
ENV CI=${CI}

ENV HOST_URL="ats.toughbyte.com"
ENV BUNDLE_PATH="/usr/local/bundle"

# Rails app lives here
WORKDIR /rails

# Install bundler
RUN gem install -N bundler:2.5.3

# Install packages needed to build gems and node modules
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl libpq-dev libvips node-gyp pkg-config python-is-python3 git curl libjemalloc2 postgresql-client

# Install JavaScript dependencies
ARG NODE_VERSION=22.7.0
ARG YARN_VERSION=1.22.22
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master

# Install application gems
COPY .ruby-version Gemfile Gemfile.lock ./
RUN bundle install && \
    bundle exec bootsnap precompile --gemfile

# Install node modules
COPY --link package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy application code
COPY --link . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Deployment options
ENV LD_PRELOAD="libjemalloc.so.2" \
    MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true"

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]
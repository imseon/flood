# WARNING:
#
# For development and debugging only. Use Dockerfile.release for production.
#
# This image bundles rTorrent for easier debugging. It is not started by default.
# Use --rtorrent argument if you wish to start the bundled rTorrent.
# For production, use rtorrent-flood instead.
#
# This Dockerfile uses contents of current folder which might contain
# secrets, uncommitted changes or other sensitive information. DO NOT
# publish the result image unless it was composed in a clean environment.

ARG BUILDPLATFORM=amd64
ARG NODE_IMAGE=docker.io/node:24.18.1-alpine

FROM --platform=$BUILDPLATFORM ${NODE_IMAGE} AS nodebuild

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ARG http_proxy
ARG https_proxy
ARG no_proxy

WORKDIR /usr/src/app/

# Copy project files
COPY . ./

RUN npm_config_proxy="$HTTP_PROXY" npm_config_https_proxy="$HTTPS_PROXY" npm i -g corepack && corepack enable && corepack install

# Fetch dependencies from npm
RUN pnpm install --frozen-lockfile

# Build assets
RUN npm run build

# Now get the clean Node.js image
FROM ${NODE_IMAGE} AS flood

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ARG http_proxy
ARG https_proxy
ARG no_proxy

WORKDIR /usr/src/app/

# Copy sources
COPY --from=nodebuild /usr/src/app ./

# Install runtime dependencies
RUN apk --no-cache add \
    mediainfo

# Create "download" user
RUN adduser -h /home/download -s /sbin/nologin --disabled-password download

# Run as "download" user
USER download

# Expose port 3000 and 4200
EXPOSE 3000
EXPOSE 4200

# Flood server in development mode
ENTRYPOINT ["npm", "--prefix=/usr/src/app/", "run", "start", "--", "--host=::"]

# Then, to start a debugging session of frontend:
# docker exec -it ${container_id} npm --prefix=/usr/src/app/ run start:development:client

# rtorrent-flood image
FROM docker.io/jesec/rtorrent:master AS rtorrent
FROM flood AS rtorrent-flood

# Copy rTorrent
COPY --from=rtorrent / /

ENTRYPOINT ["npm", "--prefix=/usr/src/app/", "run", "start", "--", "--host=::", "--rtorrent"]

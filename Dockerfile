# Build and runs
# Runs git-cache-http-server in a Debian container

FROM debian:stretch
MAINTAINER Antoine Delvaux <antoine.delvaux@gmail.com>
# Adapt or remove the proxy setting as needed, this will be used by apt-get
ENV http_proxy http://proxy:3128
# These 2 GIT_CACHE variables can be passed to change the running port and dir
ENV GIT_CACHE_PORT 1234
ENV GIT_CACHE_DIR /var/cache/git
# This is needed for npm NodeJS to find the installed module
ENV NODE_PATH=/usr/local/lib/node_modules

# Special apt config so to take haxe from unstable (latest version)
COPY docker-cp/unstable.list /etc/apt/sources.list.d/
COPY docker-cp/unstable-preferences-haxe /etc/apt/preferences.d/

# The needed tools to compile and install
RUN apt-get update && apt-get install -y \
        git \
        haxe \
        nodejs \
        npm

# Setup haxelib and install dependencies (need haxe > 3.4)
RUN haxelib setup /usr/share/haxelib && \
    haxelib install hxnodejs && \
    haxelib git jmf-npm-externs https://github.com/jonasmalacofilho/jmf-npm-externs.hx.git

# Copy the git-cache-http-server source files and compile it
COPY src /usr/local/src/
COPY build.hxml /usr/local/src/
COPY package.json /usr/local/src/
RUN cd /usr/local/src && haxe build.hxml

# Install the NodeJS application
RUN update-alternatives --install /usr/bin/node node /usr/bin/nodejs 99
RUN npm config set proxy ${http_proxy}
RUN npm config set registry http://registry.npmjs.org/
RUN npm install -g git-cache-http-server

## Prepare to start the image
RUN mkdir ${GIT_CACHE_DIR}
EXPOSE ${GIT_CACHE_PORT}
ENTRYPOINT exec git-cache-http-server --port ${GIT_CACHE_PORT} --cache-dir ${GIT_CACHE_DIR}


# syntax=docker/dockerfile:1.4

# See the README.md for some example docker invocations with this Dockerfile.

# Debian official container images; https://hub.docker.com/_/debian
FROM debian:bookworm-slim@sha256:90522eeb7e5923ee2b871c639059537b30521272f10ca86fdbbbb2b75a8c40cd

# Use Debian snapshot repositories; see https://snapshot.debian.org/
ARG DEBIAN_SNAPSHOT="20250608T000000Z"
COPY <<EOF /etc/apt/sources.list.d/debian.sources
Types: deb
URIs: http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}
Suites: bookworm bookworm-updates
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
Check-Valid-Until: no

Types: deb
URIs: http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}
Suites: bookworm-security
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
Check-Valid-Until: no
EOF

# Install Debian packages:
RUN --network=default <<EOF
set -eux
export DEBIAN_FRONTEND=noninteractive
apt-get update
# we need ruby-dev and a C toolchain to build gems with native extensions:
apt-get --assume-yes --no-install-recommends install \
    ruby bundler ruby-dev gcc g++ libc6-dev make patch xz-utils
apt-get clean
EOF

# Create the build user and home directory:
RUN --network=none <<EOF
set -eux
useradd --create-home --shell /bin/sh build
chown build:build /home/build
EOF

# Switch to the build user, and into their home directory for clear ownership:
USER build
WORKDIR /home/build/fusion-site

# Establish a build script for following steps; this may seem odd, but it
# allows the bundle/jekyll invocations to work whether running with the
# copied-in files, or files via a volume mount over the workdir. Otherwise,
# such a volume mount would also over-mount the installed gems and thus fail.
COPY --chmod=755 <<'EOF' /bin/bundlew
#!/bin/sh
set -eu
bundle config set --local gemfile '../Gemfile'
bundle config set --local path 'bundle'
case "$1" in
    exec-jekyll-build)
        shift
        set -x
        exec bundle exec jekyll build \
                --destination ../site \
                --strict_front_matter \
                --incremental \
                "$@"
        ;;
    exec-jekyll-serve)
        shift
        set -x
        exec bundle exec jekyll serve \
                --destination ../site \
                --incremental \
                --host 0.0.0.0 \
                "$@"
        ;;
    *)
        set -x
        exec bundle "$@"
        ;;
esac
EOF

# Install Ruby packages:
COPY --chown=build:build Gemfile Gemfile.lock ../
RUN --network=default bundlew install

# Fix Scss file encoding errors; https://github.com/jekyll/jekyll/issues/4268
ENV LC_ALL="C.UTF-8" LANG="en_US.UTF-8" LANGUAGE="en_US.UTF-8"

# Copy in all site sources; following commands will be rerun for every change:
COPY --chown=build:build . .

# Run the jekyll build to ensure it works as a precondition for image build;
# sadly, this "requires" network access to work, at least as of Bundler 2.3.15:
RUN --network=default bundlew exec-jekyll-build

# Default command is to run the jekyll development server:
CMD ["bundlew", "exec-jekyll-serve", "--livereload"]

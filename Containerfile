# Stage 1: Prepare the build context (ctx)
# This stage is used to copy your local build scripts and files
# into a temporary image that can be mounted into the main build stage.
FROM scratch AS ctx
COPY build_files /

# Stage 2: Build your custom Bazzite image
# This uses a Bazzite-KDE image as the base.
# We are now using the '42' tag for Fedora 42 as per your request.
FROM ghcr.io/ublue-os/bazzite-kde:42

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite-kde:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### MODIFICATIONS
## The following RUN directive mounts the 'ctx' stage and executes your 'build.sh' script.
## All modifications defined in 'build.sh' will be applied here.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    ostree container commit

### LINTING
## This line is typically for post-build validation and should not be part of the build process itself.
## It's commented out as it's not needed for the image creation.
# RUN bootc container lint

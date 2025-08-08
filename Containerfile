# Stage 1: Prepare the build context (ctx)
FROM scratch AS ctx
COPY build_files /

# Stage 2: Build your custom Bazzite image
# Using the standard Bazzite image with the "latest" tag.
FROM ghcr.io/ublue-os/bazzite:latest

### MODIFICATIONS
## The following RUN directive mounts the 'ctx' stage and executes your 'build.sh' script.
## All modifications defined in 'build.sh' will be applied here.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    ostree container commit

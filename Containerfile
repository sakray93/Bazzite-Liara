# Stage 1: Prepare the build context (ctx)
FROM scratch AS ctx
COPY build_files /

# Stage 2: Build your custom Bazzite KDE image
# Using the correct base image for Fedora 42 with KDE.
FROM ghcr.io/ublue-os/bazzite-kde:42

### MODIFICATIONS
## The following RUN directive mounts the 'ctx' stage and executes your 'build.sh' script.
## All modifications defined in 'build.sh' will be applied here.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    ostree container commit

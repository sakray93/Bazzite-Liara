# Stage 1: Prepare the build context (ctx)
FROM scratch AS ctx
COPY build_files /

# Stage 2: Build your custom Bazzite-KDE image
# Using the 'latest' tag which points to the newest build.
FROM ghcr.io/ublue-os/bazzite-kde:latest

### MODIFICATIONS
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    ostree container commit

### LINTING
# RUN bootc container lint

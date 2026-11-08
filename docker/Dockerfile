# Mission Control's source build needs the devkitA64 toolchain and the
# libjpeg-turbo port required by libstratosphere. The official devkita64 image
# already contains libnx and all currently available Switch portlibs, so no
# package-manager access is needed while building this project image.
FROM docker.io/devkitpro/devkita64:latest

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends git zip \
    && rm -rf /var/lib/apt/lists/*

ENV DEVKITPRO=/opt/devkitpro \
    DEVKITA64=/opt/devkitpro/devkitA64 \
    LIBNX=/opt/devkitpro/libnx \
    PORTLIBS=/opt/devkitpro/portlibs

ENV PATH="${DEVKITA64}/bin:${DEVKITPRO}/tools/bin:${DEVKITPRO}/portlibs/switch/bin:${PATH}"

WORKDIR /workspace

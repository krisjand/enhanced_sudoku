FROM debian:12-slim

ARG FLUTTER_VERSION=3.44.0

ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"
ENV PUB_CACHE=/root/.pub-cache
ENV FLUTTER_VERSION=${FLUTTER_VERSION}

# Install dependencies, download Flutter, pre-warm, and clean up in a single layer
# so that deleted files do not persist in the image.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/* \
    # Download Flutter as a tarball — avoids the .git directory overhead from git clone
    && curl -fsSL \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        -o /tmp/flutter.tar.xz \
    && tar xf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    # Remove directories not needed for unit/widget test CI
    && rm -rf \
        "${FLUTTER_HOME}/dev/benchmarks" \
        "${FLUTTER_HOME}/dev/docs" \
        "${FLUTTER_HOME}/dev/integration_tests" \
        "${FLUTTER_HOME}/examples" \
    # Disable analytics and pre-warm only the artifacts needed for unit/widget tests
    && flutter config --no-analytics \
    && flutter precache --no-android --no-ios --no-linux --no-windows --no-macos --no-fuchsia --no-web \
    && flutter --version

FROM ubuntu:24.04

ARG FLUTTER_VERSION=3.44.0

ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"
ENV PUB_CACHE=/root/.pub-cache
ENV FLUTTER_VERSION=${FLUTTER_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter at the pinned version
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
    https://github.com/flutter/flutter.git ${FLUTTER_HOME}

# Disable analytics, pre-warm Dart SDK and engine artifacts for unit/widget tests.
# Excludes Android, iOS, and desktop to keep the image lean.
RUN flutter config --no-analytics \
    && flutter precache --no-android --no-ios --no-linux --no-windows --no-macos --no-fuchsia \
    && flutter --version

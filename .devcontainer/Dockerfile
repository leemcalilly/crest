# Development container: the full Ruby image (build tools + git included)
# plus the runtime libraries the app needs. Production uses the top-level
# Dockerfile; this one exists so a dev copy runs identically anywhere —
# VS Code, GitHub Codespaces, or a coding-agent cloud environment.
FROM docker.io/library/ruby:4.0.1

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libvips sqlite3 curl && \
    rm -rf /var/lib/apt/lists/*

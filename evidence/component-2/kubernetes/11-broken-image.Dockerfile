# THROWAWAY demo image, never committed: same layers as 1.0.0 but the process
# never opens the HTTP port, so the readiness probe on /health cannot pass.
FROM bu-campus-api:1.0.0
ENV APP_VERSION=2.0.0-broken
ENTRYPOINT ["sh", "-c", "echo 'starting v2.0.0-broken (bug: server never starts)'; sleep 86400"]

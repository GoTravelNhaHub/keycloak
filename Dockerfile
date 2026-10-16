# Production image: pre-built (optimized) Keycloak so startup skips the build step.
#   docker build -t gotravelnha/keycloak:26.8.1 .
FROM quay.io/keycloak/keycloak:26.8.1 AS builder

# Build-time options. Changing any of these requires a rebuild.
ENV KC_DB=postgres
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
# Serve /health/* on the main port (8080) too, so a PaaS health check (Render) can reach it.
# /metrics stays on the management port 9000, which is not exposed publicly.
ENV KC_HTTP_MANAGEMENT_HEALTH_ENABLED=false

COPY themes/ /opt/keycloak/themes/
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.8.1
COPY --from=builder /opt/keycloak/ /opt/keycloak/
COPY realm/ /opt/keycloak/data/import/
COPY --chmod=755 docker/entrypoint.sh /opt/keycloak/bin/entrypoint.sh

ENTRYPOINT ["/opt/keycloak/bin/entrypoint.sh"]
CMD ["start", "--optimized", "--import-realm"]

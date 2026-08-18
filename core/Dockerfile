FROM ghcr.io/alpkeskin/rota:2.2.1@sha256:098bb83a9e316ed75fbeeed4d350e57c60621aa4b1b52abfbb9d26a261bffe62

USER root
RUN apk add --no-cache postgresql-client
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint
RUN chmod 0755 /usr/local/bin/railway-entrypoint
USER appuser

ENTRYPOINT ["/usr/local/bin/railway-entrypoint"]

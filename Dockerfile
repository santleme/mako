# Minimal Plow Hermes variant for Mako.
# The base is immutable and already contains the runtime, Plow integration,
# persistent Hermes home, s6-overlay, and base persona.
FROM public.ecr.aws/e1h7x4a2/plow-cloud-agents:base-51f83158a70a383f03a4d03dbd8b6ea102cf0361@sha256:253d7ed3409effa7fa59113d93b4b79bb731d8264cdaf4cd60294924d0110a2e

LABEL org.opencontainers.image.title="Mako"
LABEL org.opencontainers.image.description="Mako turns real life into an RPG through SMS"
LABEL org.opencontainers.image.source="https://github.com/santleme/mako"
LABEL org.opencontainers.image.licenses="MIT"

# plow-init composes the final SOUL.md from the base persona and this file on
# every boot. Never copy an identity into /var/lib/hermes/SOUL.md.
COPY --chown=0:0 persona.md /opt/hermes/plow-seed/persona.md
RUN chmod 0644 /opt/hermes/plow-seed/persona.md

# Mako's product-specific skill is shipped both as the persistent-home seed and
# as the immutable bundled source, following the official Hermes variant
# contract. The runtime reconciles the home copy without requiring a database.
COPY --chown=10000:10000 skills/ /var/lib/hermes/skills/
COPY --chown=10000:10000 skills/ /opt/hermes/skills/
RUN find /var/lib/hermes/skills /opt/hermes/skills -type d -exec chmod 0755 {} + \
 && find /var/lib/hermes/skills /opt/hermes/skills -type f -exec chmod 0644 {} +

# Mako logo for explicit Plow Chat MEDIA delivery. Pets are intentionally
# deferred and are not copied into the runtime image.
COPY assets/mako-logo.png /srv/plow-assets/mako-logo.png
RUN chmod 0644 /srv/plow-assets/mako-logo.png \
 && chown root:root /srv/plow-assets/mako-logo.png

# Keep the Agent Index install identity and usage ledger in the named Hermes
# volume used by compose. The client itself is fetched, pinned, and verified;
# the Plow bearer is supplied only at runtime.
COPY vendor/client.pin /opt/plow/agent-index-client.pin
RUN set -eu; \
    sha="$(sed -n 's/^sha=//p' /opt/plow/agent-index-client.pin)"; \
    want="$(sed -n 's/^sha256=//p' /opt/plow/agent-index-client.pin)"; \
    path="$(sed -n 's/^path=//p' /opt/plow/agent-index-client.pin)"; \
    curl -fsS --max-time 60 -o /opt/plow/agent-index-client.py \
      "https://raw.githubusercontent.com/plow-pbc/agent-index-client/${sha}/${path}"; \
    got="$(sha256sum /opt/plow/agent-index-client.py | cut -d' ' -f1)"; \
    [ "$got" = "$want" ] || { echo "agent-index client is $got, pin says $want" >&2; exit 1; }; \
    chmod 0644 /opt/plow/agent-index-client.py

COPY LICENSE NOTICE /usr/share/doc/mako/
COPY image/s6-overlay/ /etc/s6-overlay/
RUN chmod 0755 /etc/s6-overlay/s6-rc.d/mako-sms-mode/up \
 && chmod 0755 /etc/s6-overlay/scripts/mako-sms-mode.sh

# A named mount is recommended; compose.yml supplies one for local runs.
VOLUME ["/var/lib/hermes"]

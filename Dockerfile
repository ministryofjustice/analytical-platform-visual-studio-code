FROM ghcr.io/ministryofjustice/analytical-platform-cloud-development-environment-base:1.13.0@sha256:302cecbda13d3fa284bfe0630f18dbaae9f0c37b11c9193a9dc50a44f915593a

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform (analytical-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="Visual Studio Code" \
      org.opencontainers.image.description="Visual Studio Code image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/analytical-platform-visual-studio-code"

ENV VISUAL_STUDIO_CODE_VERSION="1.97.2-1739406807"

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

USER root

# First Run Notice
COPY --chown="${CONTAINER_USER}:${CONTAINER_GROUP}" --chmod=0644 src${ANALYTICAL_PLATFORM_DIRECTORY}/first-run-notice.txt ${ANALYTICAL_PLATFORM_DIRECTORY}/first-run-notice.txt

# Visual Studio Code
RUN <<EOF
curl --location --fail-with-body \
  "https://packages.microsoft.com/keys/microsoft.asc" \
  --output microsoft.asc

cat microsoft.asc | gpg --dearmor --output packages.microsoft.gpg

install -D --owner root --group root --mode 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg

echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list

apt-get update --yes

apt-get install --yes "code=${VISUAL_STUDIO_CODE_VERSION}"

apt-get clean --yes

rm --force --recursive microsoft.asc packages.microsoft.gpg /var/lib/apt/lists/*
EOF

USER ${CONTAINER_USER}
WORKDIR /home/${CONTAINER_USER}
EXPOSE 8080
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/healthcheck.sh /usr/local/bin/healthcheck.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["/usr/local/bin/healthcheck.sh"]

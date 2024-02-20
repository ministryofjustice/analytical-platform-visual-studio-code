FROM public.ecr.aws/ubuntu/ubuntu@sha256:98bdc90ad3fc207b7d0a60ce166b62d410c741d35b17b615404bc060b9da989f

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform (analytical-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="Visual Studio Code" \
      org.opencontainers.image.description="Visual Studio Code image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/analytical-platform"

ENV CONTAINER_USER="analyticalplatform" \
    CONTAINER_UID="1000" \
    CONTAINER_GROUP="analyticalplatform" \
    CONTAINER_GID="1000" \
    DEBIAN_FRONTEND="noninteractive" \
    VISUAL_STUDIO_CODE_VERSION="1.86.2-1707854558" \
    AWS_CLI_VERSION="2.15.21" \
    MINICONDA_VERSION="23.11.0-2" \
    MINICONDA_SHA265="35a58b8961e1187e7311b979968662c6223e86e1451191bed2e67a72b6bd0658" \
    PATH="/opt/conda/bin:${PATH}"

# User
RUN groupadd \
      --gid ${CONTAINER_GID} \
      ${CONTAINER_GROUP} \
    && useradd \
         --uid ${CONTAINER_UID} \
         --gid ${CONTAINER_GROUP} \
         --create-home \
         --shell /bin/bash \
         ${CONTAINER_USER}

# Base
RUN apt-get update --yes \
    && apt-get install --yes \
         "apt-transport-https=2.4.11" \
         "curl=7.81.0-1ubuntu1.15" \
         "git=1:2.34.1-1ubuntu1.10" \
         "gpg=2.2.27-3ubuntu2.1" \
         "python3.10=3.10.12-1~22.04.3" \
         "python3-pip=22.0.2+dfsg-1ubuntu0.4" \
         "unzip=6.0-26ubuntu3.2" \
    && apt-get clean --yes \
    && rm --force --recursive /var/lib/apt/lists/*

# Visaual Studio Code
RUN curl --location --fail-with-body \
      "https://packages.microsoft.com/keys/microsoft.asc" \
      --output microsoft.asc \
    && cat microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -D --owner root --group root --mode 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg \
    && echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list \
    && apt-get update --yes \
    && apt-get install --yes \
         "code=${VISUAL_STUDIO_CODE_VERSION}" \
    && apt-get clean --yes \
    && rm --force --recursive /var/lib/apt/lists/*

# AWS CLI
COPY --chown=nobody:nobody --chmod=0755 src/opt/aws-cli/aws-cli@amazon.com.asc /opt/aws-cli/aws-cli@amazon.com.asc
RUN gpg --import /opt/aws-cli/aws-cli@amazon.com.asc \
    && curl --location --fail-with-body \
         "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip.sig" \
         --output "awscliv2.sig" \
    && curl --location --fail-with-body \
         "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" \
         --output "awscliv2.zip" \
    && gpg --verify awscliv2.sig awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm --force --recursive awscliv2.sig awscliv2.zip aws

# Miniconda
RUN curl --location --fail-with-body \
         "https://repo.anaconda.com/miniconda/Miniconda3-py310_${MINICONDA_VERSION}-Linux-x86_64.sh" \
         --output "miniconda.sh" \
    && echo "${MINICONDA_SHA265} miniconda.sh" | sha256sum --check \
    && bash miniconda.sh -b -p /opt/conda \
    && rm --force miniconda.sh

COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/healthcheck.sh /usr/local/bin/healthcheck.sh

USER ${CONTAINER_USER}

WORKDIR /home/${CONTAINER_USER}

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["/usr/local/bin/healthcheck.sh"]

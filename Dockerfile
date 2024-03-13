FROM public.ecr.aws/ubuntu/ubuntu@sha256:722b3bddfe96b95441f626cf94974d79213090ecbd16954f71d7c080fb413561

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
    VISUAL_STUDIO_CODE_VERSION="1.87.2-1709912201" \
    AWS_CLI_VERSION="2.15.28" \
    MINICONDA_VERSION="24.1.2-0" \
    MINICONDA_SHA265="8eb5999c2f7ac6189690d95ae5ec911032fa6697ae4b34eb3235802086566d78" \
    PATH="/opt/conda/bin:${PATH}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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
         "jq=1.6-2.1ubuntu3" \
         "mandoc=1.14.6-1" \
         "python3.10=3.10.12-1~22.04.3" \
         "python3-pip=22.0.2+dfsg-1ubuntu0.4" \
         "unzip=6.0-26ubuntu3.2" \
    && apt-get clean --yes \
    && rm --force --recursive /var/lib/apt/lists/*

COPY src/opt/visual-studio-code/first-run-notice.txt /opt/visual-studio-code/first-run-notice.txt

RUN cat <<EOF >> /etc/bash.bashrc

# This is a first run notice for Visual Studio Code
if [[ -t 1 ]] && [[ "\${TERM_PROGRAM}" = "vscode" ]] && [[ ! -f "/home/analyticalplatform/.vscode/first-run-notice-already-displayed" ]]; then
    cat /opt/visual-studio-code/first-run-notice.txt
    # Mark first run notice as displayed after 10s to avoid problems with fast terminal refreshes hiding it
    mkdir --parents "/home/analyticalplatform/.vscode"
    ((sleep 10s; touch "/home/analyticalplatform/.vscode/first-run-notice-already-displayed") &)
fi

EOF

# Visual Studio Code
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

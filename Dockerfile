FROM public.ecr.aws/ubuntu/ubuntu@sha256:83a9f5d38a7a0fc010833ca22457910f9cdd1c2134c8b857edab1e470628840d

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform (analytical-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="Visual Studio Code" \
      org.opencontainers.image.description="Visual Studio Code image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/analytical-platform-visual-studio-code"

ENV CONTAINER_USER="analyticalplatform" \
    CONTAINER_UID="1000" \
    CONTAINER_GROUP="analyticalplatform" \
    CONTAINER_GID="1000" \
    DEBIAN_FRONTEND="noninteractive" \
    VISUAL_STUDIO_CODE_VERSION="1.88.0-1712152114" \
    AWS_CLI_VERSION="2.15.37" \
    CORRETTO_VERSION="1:21.0.2.14-1" \
    MINICONDA_VERSION="24.1.2-0" \
    MINICONDA_SHA256="8eb5999c2f7ac6189690d95ae5ec911032fa6697ae4b34eb3235802086566d78" \
    DOTNET_SDK_VERSION="8.0.204-1" \
    OLLAMA_VERSION="0.1.31" \
    OLLAMA_SHA256="9d9a24ed741bf9d88c8e9df6865371681316aee298433d0291e86295045bfa96" \
    PATH="/opt/conda/bin:${HOME}/.local/bin:${PATH}"

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

# User Configuration
RUN <<EOF
groupadd \
  --gid ${CONTAINER_GID} \
  ${CONTAINER_GROUP}

useradd \
  --uid ${CONTAINER_UID} \
  --gid ${CONTAINER_GROUP} \
  --create-home \
  --shell /bin/bash \
  ${CONTAINER_USER}
EOF

# Base
RUN <<EOF
apt-get update --yes

apt-get install --yes \
  "apt-transport-https=2.4.12" \
  "ca-certificates=20230311ubuntu0.22.04.1" \
  "curl=7.81.0-1ubuntu1.16" \
  "git=1:2.34.1-1ubuntu1.10" \
  "gpg=2.2.27-3ubuntu2.1" \
  "jq=1.6-2.1ubuntu3" \
  "mandoc=1.14.6-1" \
  "python3.10=3.10.12-1~22.04.3" \
  "python3-pip=22.0.2+dfsg-1ubuntu0.4" \
  "unzip=6.0-26ubuntu3.2"

apt-get clean --yes

rm --force --recursive /var/lib/apt/lists/*

install --directory --owner ${CONTAINER_USER} --group ${CONTAINER_GROUP} --mode 0755 /opt/visual-studio-code
EOF

# Backup Bash configuration
RUN <<EOF
cp /home/analyticalplatform/.bashrc /opt/visual-studio-code/.bashrc

cp /home/analyticalplatform/.bash_logout /opt/visual-studio-code/.bash_logout

cp /home/analyticalplatform/.profile /opt/visual-studio-code/.profile
EOF

# First run notice
COPY src/opt/visual-studio-code/first-run-notice.txt /opt/visual-studio-code/first-run-notice.txt
COPY src/etc/bash.bashrc.snippet /etc/bash.bashrc.snippet
RUN <<EOF
cat /etc/bash.bashrc.snippet >> /etc/bash.bashrc
EOF

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

rm --force --recursive packages.microsoft.gpg /var/lib/apt/lists/*
EOF

# AWS CLI
COPY --chown=nobody:nobody --chmod=0755 src/opt/aws-cli/aws-cli@amazon.com.asc /opt/aws-cli/aws-cli@amazon.com.asc
RUN <<EOF
gpg --import /opt/aws-cli/aws-cli@amazon.com.asc

curl --location --fail-with-body \
  "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip.sig" \
  --output "awscliv2.sig"

curl --location --fail-with-body \
  "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" \
  --output "awscliv2.zip"

gpg --verify awscliv2.sig awscliv2.zip

unzip awscliv2.zip

./aws/install

rm --force --recursive awscliv2.sig awscliv2.zip aws
EOF

# Amazon Corretto
RUN <<EOF
curl --location --fail-with-body \
  "https://apt.corretto.aws/corretto.key" \
  --output corretto.key
cat corretto.key | gpg --dearmor --output corretto-keyring.gpg

install -D --owner root --group root --mode 644 corretto-keyring.gpg /etc/apt/keyrings/corretto-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" > /etc/apt/sources.list.d/corretto.list

apt-get update --yes

apt-get install --yes "java-21-amazon-corretto-jdk=${CORRETTO_VERSION}"

apt-get clean --yes

rm --force --recursive corretto-keyring.gpg /var/lib/apt/lists/*
EOF

# Miniconda
RUN <<EOF
curl --location --fail-with-body \
  "https://repo.anaconda.com/miniconda/Miniconda3-py310_${MINICONDA_VERSION}-Linux-x86_64.sh" \
  --output "miniconda.sh"

echo "${MINICONDA_SHA256} miniconda.sh" | sha256sum --check

bash miniconda.sh -b -p /opt/conda

chown --recursive "${CONTAINER_USER}":"${CONTAINER_GROUP}" /opt/conda

rm --force miniconda.sh
EOF

# .NET SDK
RUN <<EOF
curl --location --fail-with-body \
  "https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb" \
  --output "packages-microsoft-prod.deb"

apt-get install --yes ./packages-microsoft-prod.deb

apt-get update --yes

apt-get install --yes "dotnet-sdk-8.0=${DOTNET_SDK_VERSION}"

apt-get clean --yes

rm --force --recursive /var/lib/apt/lists/*

rm --force packages-microsoft-prod.deb
EOF

# Ollama
RUN <<EOF
curl --location --fail-with-body \
  "https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-amd64" \
  --output "ollama"

echo "${OLLAMA_SHA256} ollama" | sha256sum --check

install --owner=root --group=root --mode=775 ollama /usr/local/bin/ollama

rm --force ollama
EOF

USER ${CONTAINER_USER}
WORKDIR /home/${CONTAINER_USER}
EXPOSE 8080
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/healthcheck.sh /usr/local/bin/healthcheck.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["/usr/local/bin/healthcheck.sh"]

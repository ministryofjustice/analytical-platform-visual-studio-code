FROM public.ecr.aws/ubuntu/ubuntu@sha256:d55d834bd8b4e1b720fe743ab90a295e8f50ca280aa8c02700a5440461ea160e

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
    VISUAL_STUDIO_CODE_VERSION="1.88.1-1712771838" \
    AWS_CLI_VERSION="2.15.43" \
    CORRETTO_VERSION="1:21.0.3.9-1" \
    MINICONDA_VERSION="24.3.0-0" \
    MINICONDA_SHA256="96a44849ff17e960eeb8877ecd9055246381c4d4f2d031263b63fa7e2e930af1" \
    DOTNET_SDK_VERSION="8.0.104-0ubuntu1" \
    OLLAMA_VERSION="0.1.32" \
    OLLAMA_SHA256="539e8e1df2f74263fc56e0939cfc3f014a1addf02b07a06cae5cb42d810eb746" \
    PATH="/opt/conda/bin:${HOME}/.local/bin:${PATH}"

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

# User Configuration
RUN <<EOF
# Ubuntu have added a user with UID 1000 already, but this is the UID we use in the tooling cluster
userdel --remove --force ubuntu

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
  "apt-transport-https=2.7.14build2" \
  "ca-certificates=20240203" \
  "curl=8.5.0-2ubuntu10.1" \
  "git=1:2.43.0-1ubuntu7" \
  "gpg=2.4.4-2ubuntu17" \
  "jq=1.7.1-3build1" \
  "mandoc=1.14.6-1" \
  "python3.12=3.12.3-1" \
  "python3-pip=24.0+dfsg-1ubuntu1" \
  "unzip=6.0-28ubuntu4"

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
  "https://repo.anaconda.com/miniconda/Miniconda3-py312_${MINICONDA_VERSION}-Linux-x86_64.sh" \
  --output "miniconda.sh"

echo "${MINICONDA_SHA256} miniconda.sh" | sha256sum --check

bash miniconda.sh -b -p /opt/conda

chown --recursive "${CONTAINER_USER}":"${CONTAINER_GROUP}" /opt/conda

rm --force miniconda.sh
EOF

# .NET SDK
RUN <<EOF
curl --location --fail-with-body \
  "https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb" \
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

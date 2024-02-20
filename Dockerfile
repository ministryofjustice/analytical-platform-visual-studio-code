# Use the official Ubuntu base image, latest version
FROM ubuntu:latest
# Create User
RUN useradd --create-home --shell /bin/bash vscode
# Set the working directory inside the container&& \
WORKDIR /vscode
# Install any necessary dependencies
RUN apt-get update
# Setup the code repository
RUN apt-get install -y wget gpg curl unzip mandoc && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' && \
    rm -f packages.microsoft.gpg
# Install Visual Studio Code from the repository
RUN apt install -y apt-transport-https && \
    apt update && \
    apt install -y code

ENV AWS_CLI_VERSSION="2.15.21"
COPY ./public.key public-key-file-name

# Install AWS cli
RUN curl -o awscli.tar.gz "https://awscli.amazonaws.com/awscli-${AWS_CLI_VERSSION}.tar.gz" && \
    gpg --import public-key-file-name && \
    curl -o awscliv2.sig "https://awscli.amazonaws.com/awscli-${AWS_CLI_VERSSION}.tar.gz.sig"  && \
    gpg --verify awscliv2.sig awscli.tar.gz && \
    tar -xzf awscli.tar.gz 

ENV MINICONDA_SHA="35a58b8961e1187e7311b979968662c6223e86e1451191bed2e67a72b6bd0658"
ENV MINICONDA_VERSION="23.11.0-2"
# Install miniconda
RUN mkdir -p /opt/miniconda3 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-py310_${MINICONDA_VERSION}-Linux-x86_64.sh   -O /opt/miniconda3/miniconda.sh && \
    echo "${MINICONDA_SHA} /opt/miniconda3/miniconda.sh" | sha256sum -c && \
    bash /opt/miniconda3/miniconda.sh -b -u -p /opt/miniconda3 && \
    rm -rf /opt/miniconda3/miniconda.sh 



ENV PATH="${PATH}:/opt/miniconda3/bin"

# Switch user
#USER vscode
ENTRYPOINT ["code", "serve-web", "--host", "0.0.0.0", "--without-connection-token"]
# Analytical Platform Visual Studio Code

[![repo standards badge](https://img.shields.io/endpoint?labelColor=231f20&color=005ea5&style=for-the-badge&label=MoJ%20Compliant&url=https%3A%2F%2Foperations-engineering-reports.cloud-platform.service.justice.gov.uk%2Fapi%2Fv1%2Fcompliant_public_repositories%2Fendpoint%2Ftemplate-repository&logo=data:image/png;base64,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)](https://operations-engineering-reports.cloud-platform.service.justice.gov.uk/public-report/analytical-platform-visual-studio-code)

This repository contains the Visual Studio Code container image for use in the Analytical Platform.

This repository is managed in Terraform [here](https://github.com/ministryofjustice/data-platform/blob/main/terraform/github/analytical-platform-repositories.tf#L286).

## Features

The base container image is [Ubuntu 22.04 LTS](https://gallery.ecr.aws/ubuntu/ubuntu).

Additionally the following tools are installed:

- [AWS CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/index.html)
- [Miniconda](https://docs.anaconda.com/free/miniconda/index.html)
- [Ollama](https://ollama.com/)

## Running Locally

### Build

```bash
docker build --platform linux/amd64 --file Dockerfile --tag analytical-platform.service.justice.gov.uk/visual-studio-code:local .
```

### Run

```bash
docker run -it --rm \
  --platform linux/amd64 \
  --publish 8080:8080 \
  --hostname code \
  --name analytical-platform-code \
  analytical-platform.service.justice.gov.uk/visual-studio-code:local
```

### Use

Open a browser <http://localhost:8080/?folder=/home/analyticalplatform/workspace>

## Versions

### Ubuntu

Generally Dependabot does this, but the following command will return the digest:

```bash
docker pull --platform linux/amd64 public.ecr.aws/ubuntu/ubuntu:22.04
docker image inspect --format='{{index .RepoDigests 0}}' public.ecr.aws/ubuntu/ubuntu:22.04
```

### APT Packages

To find latest APT package versions, you can run the following:

```bash
docker run -it --rm --platform linux/amd64 public.ecr.aws/ubuntu/ubuntu:22.04

apt-get update

apt-cache policy ${PACKAGE} # for example curl, git or gpg
```

### Visual Studio Code

Releases for Visual Studio Code are published on [GitHub](https://github.com/microsoft/vscode/releases), but we specifically want the Debian package version, to obtain this you can run the following:

```bash
curl --silent https://packages.microsoft.com/repos/code/pool/main/c/code/ | grep $(curl --silent https://api.github.com/repos/microsoft/vscode/releases/latest | jq -r .tag_name) | grep amd64
```

This will return a string like:

```bash
<a href="code_1.86.2-1707854558_amd64.deb">code_1.86.2-1707854558_amd64.deb</a> ...
```

From that, we want `1.86.2-1707854558`.

### AWS CLI

Releases for AWS CLI are maintained on [GitHub](https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst).

The GPG public key used for verification of AWS CLI is not hosted in a way where we can consume it programatically, instead its on [this](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-version.html) page
under "(Optional) Verifying the integrity of your downloaded ZIP file".

As of 20/02/24, the GPG public key used for verifying AWS CLI expires 26/07/24, but there is an [issue](https://github.com/aws/aws-cli/issues/6230) to track it.

### Miniconda

Releases for Miniconda are maintained on [docs.anaconda.com](https://docs.anaconda.com/free/miniconda/miniconda-release-notes/), from there we can use [repo.anaconda.com](https://repo.anaconda.com/miniconda/) to determine the artefact name and SHA256 based on a version. We currently use `py310`, `Linux` and `x86_64`variant.

### Ollama

Ollama is a tool that allows you to run open-source large language models (LLMs) locally on your machine. It supports a variety of models, including Llama 2, Code Llama, and others.

Ollama don't currently provide SHA256 checksum for their installation file. For now, a checksum was acquired by running the following command locally:
`curl --location --fail-with-body "https://github.com/ollama/ollama/releases/download/v0.1.29/ollama-linux-amd64" | sha256sum`

# build
FROM golang:1.27.3-alpine3.24 AS builder
RUN apk add --no-cache git
ARG TERRAFORM_DOCS_VERSION=0.24.0
ARG NEWRES_VERSION=v3.0.0-20260525022454-33a9264ce60b
RUN CGO_ENABLED=0 go install github.com/terraform-docs/terraform-docs@v${TERRAFORM_DOCS_VERSION} && \
  CGO_ENABLED=0 go install github.com/lonegunmanb/newres/v3@${NEWRES_VERSION}

# run
FROM ubuntu:24.04

ARG POWERSHELL_VERSION=7.6.8
ARG GITHUB_CLI_VERSION=2.103.2
ARG GITHUB_CLI_URL=https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_amd64.tar.gz
ARG GITHUB_CLI_SHA256=62ccf747115ddc61237efffdde66a3c8f70ba249433dc64f70801089b59c59c8
ARG DOCKER_CLI_VERSION=29.9.2
ARG DOCKER_COMPOSE_VERSION=5.6.1
ARG TRIVY_VERSION=0.76.1
ARG TERRAFORM_VERSION=1.17.0
ARG TFLINT_VERSION=0.65.0
ARG AZ_MANAGED_SERVICE_IDENTITY_VERSION=2.1.0
ARG AZ_RESOURCES_VERSION=10.2.1

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  bash \
  binutils \
  ca-certificates \
  curl \
  git \
  gzip \
  jq \
  libkrb5-3 \
  liblttng-ust1t64 \
  libunwind8 \
  openssl \
  tar \
  tzdata \
  unzip \
  wget && \
  curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb && \
  dpkg -i /tmp/packages-microsoft-prod.deb && \
  mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" > /etc/apt/sources.list.d/docker.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  powershell=${POWERSHELL_VERSION}-1.deb \
  docker-ce-cli=5:${DOCKER_CLI_VERSION}-1~ubuntu.24.04~noble \
  docker-compose-plugin=${DOCKER_COMPOSE_VERSION}-1~ubuntu.24.04~noble && \
  ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose && \
  rm -f /tmp/packages-microsoft-prod.deb && \
  rm -rf /var/lib/apt/lists/*

RUN curl -fsSL ${GITHUB_CLI_URL} -o /tmp/gh.tar.gz && \
  echo "${GITHUB_CLI_SHA256}  /tmp/gh.tar.gz" | sha256sum -c - && \
  tar -xzf /tmp/gh.tar.gz -C /tmp && \
  mv /tmp/gh_${GITHUB_CLI_VERSION}_linux_amd64/bin/gh /usr/local/bin/ && \
  rm -rf /tmp/gh.tar.gz /tmp/gh_${GITHUB_CLI_VERSION}_linux_amd64

RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  mv terraform /usr/local/bin/ && \
  rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  (strip /usr/local/bin/terraform || true)

RUN wget -q https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip && \
  unzip tflint_linux_amd64.zip && \
  mv tflint /usr/local/bin/ && \
  rm tflint_linux_amd64.zip && \
  (strip /usr/local/bin/tflint || true)

RUN wget -q https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
  tar -xzf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
  mv trivy /usr/local/bin/ && \
  rm trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
  (strip /usr/local/bin/trivy || true)

COPY --from=builder /go/bin/terraform-docs /usr/local/bin/
COPY --from=builder /go/bin/newres /usr/local/bin/

COPY .tflint.hcl /root/.tflint.hcl

RUN tflint --init --enable-plugin=azurerm && \
  tflint --version

RUN pwsh -Command " \
  Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted; \
  Install-Module -Name Az.ManagedServiceIdentity -RequiredVersion ${AZ_MANAGED_SERVICE_IDENTITY_VERSION} -Force -Scope AllUsers; \
  Install-Module -Name Az.Resources -RequiredVersion ${AZ_RESOURCES_VERSION} -Force -Scope AllUsers"

VOLUME ["/var/run/docker.sock"]

CMD ["sh"]

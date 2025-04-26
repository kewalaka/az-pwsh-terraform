# build 
FROM golang:1.24-alpine AS builder
RUN apk add --no-cache git
RUN go install github.com/terraform-docs/terraform-docs@v0.20.0
ARG NEWRES_VERSION=a535fe92925845dfa033a3db71adf7d65511cbf3
RUN go install github.com/lonegunmanb/newres/v3@$NEWRES_VERSION

# run
FROM alpine:3.21

ARG POWERSHELL_VERSION=7.5.0
ARG GITHUB_CLI_VERSION=2.71.0
ARG GITHUB_CLI_URL=https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_amd64.tar.gz
ARG GITHUB_CLI_SHA256=c85ef9d7b35f0a13a656e352091005cd0a766e5e3a6006e821b810486c81cacd

ARG TRIVY_VERSION=0.61.1
ARG TERRAFORM_VERSION=1.11.4
ARG TFLINT_VERSION=0.56.0

RUN apk add --no-cache \
  bash \
  binutils \
  ca-certificates \
  curl \
  docker-cli \
  docker-compose \
  git \
  gzip \
  icu \
  icu-data-full \
  jq \
  krb5 \
  libgcc \
  libintl \
  libstdc++ \
  libunwind \
  lttng-ust \
  openssl \
  tar \
  tzdata \
  unzip \
  wget && \
  rm -rf /var/cache/apk/*

RUN wget -q https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-musl-x64.tar.gz && \
  mkdir -p /opt/microsoft/powershell/7 && \
  tar -xzf powershell-${POWERSHELL_VERSION}-linux-musl-x64.tar.gz -C /opt/microsoft/powershell/7 && \
  ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
  chmod +x /opt/microsoft/powershell/7/pwsh && \
  rm powershell-${POWERSHELL_VERSION}-linux-musl-x64.tar.gz && \
  rm -rf /opt/microsoft/powershell/7/{LICENSE.txt,ThirdPartyNotices.txt,*.md,test,docs}

RUN curl -sL ${GITHUB_CLI_URL} -o /tmp/gh.tar.gz && \
  echo "${GITHUB_CLI_SHA256}  /tmp/gh.tar.gz" | sha256sum -c - && \
  tar -xzf /tmp/gh.tar.gz -C /tmp && \
  mv /tmp/gh_${GITHUB_CLI_VERSION}_linux_amd64/bin/gh /usr/local/bin/ && \
  rm -rf /tmp/*

RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  mv terraform /usr/local/bin/ && \
  rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  strip /usr/local/bin/terraform || true

RUN wget -q https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip && \
  unzip tflint_linux_amd64.zip && \
  mv tflint /usr/local/bin/ && \
  rm tflint_linux_amd64.zip && \
  strip /usr/local/bin/tflint || true

RUN wget -q https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
  tar -xzf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
  mv trivy /usr/local/bin/ && \
  rm trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
  strip /usr/local/bin/trivy || true

COPY --from=builder /go/bin/terraform-docs /usr/local/bin/
COPY --from=builder /go/bin/newres /usr/local/bin/

COPY .tflint.hcl /root/.tflint.hcl

RUN tflint --init --enable-plugin=azurerm && \
  tflint --version

RUN pwsh -Command " \
  Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted; \
  Install-Module -Name Az.ManagedServiceIdentity -Force -Scope AllUsers; \
  Install-Module -Name Az.Resources -Force -Scope AllUsers"

VOLUME ["/var/run/docker.sock"]

CMD ["sh"]

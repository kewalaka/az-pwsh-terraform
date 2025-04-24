# build 
FROM golang:1.24-alpine AS tfdocs-builder
RUN apk add --no-cache git
RUN go install github.com/terraform-docs/terraform-docs@v0.20.0

# run
FROM alpine:3.21

ARG POWERSHELL_VERSION=7.5.0
ARG GITHUB_CLI_VERSION=2.71.0
ARG GITHUB_CLI_URL=https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_amd64.tar.gz
ARG GITHUB_CLI_SHA256=c85ef9d7b35f0a13a656e352091005cd0a766e5e3a6006e821b810486c81cacd

ARG TRIVY_VERSION=0.50.2
ARG TERRAFORM_VERSION=1.11.4
ARG TFLINT_VERSION=0.56.0

RUN apk add --no-cache \
  bash \
  curl \
  wget \
  unzip \
  tar \
  gzip \
  jq \
  openssl \
  ca-certificates \
  libintl \
  libgcc \
  libstdc++ \
  libunwind \
  icu-data-full \
  krb5 \
  tzdata \
  lttng-ust \
  docker-cli \
  docker-compose \
  py3-pip \
  git \
  binutils && \
  rm -rf /var/cache/apk/*

RUN wget https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-musl-x64.tar.gz && \
  mkdir -p /opt/microsoft/powershell/7 && \
  tar -xzf powershell-${POWERSHELL_VERSION}-linux-musl-x64.tar.gz -C /opt/microsoft/powershell/7 && \
  ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
  rm powershell-${POWERSHELL_VERSION}-linux-musl-x64.tar.gz && \
  rm -rf /opt/microsoft/powershell/7/{LICENSE.txt,ThirdPartyNotices.txt,*.md,test,docs}

RUN curl -L ${GITHUB_CLI_URL} -o /tmp/gh.tar.gz && \
  echo "${GITHUB_CLI_SHA256}  /tmp/gh.tar.gz" | sha256sum -c - && \
  tar -xzf /tmp/gh.tar.gz -C /tmp && \
  mv /tmp/gh_${GITHUB_CLI_VERSION}_linux_amd64/bin/gh /usr/local/bin/ && \
  rm -rf /tmp/*

RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  mv terraform /usr/local/bin/ && \
  rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  strip /usr/local/bin/terraform || true

RUN wget https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip && \
  unzip tflint_linux_amd64.zip && \
  mv tflint /usr/local/bin/ && \
  rm tflint_linux_amd64.zip && \
  strip /usr/local/bin/tflint || true

RUN pip install --no-cache-dir checkov && \
  find /usr/lib/python3*/ -type d -name "__pycache__" -exec rm -r {} + || true

RUN wget https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
  tar -xzf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
  mv trivy /usr/local/bin/ && \
  rm trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
  strip /usr/local/bin/trivy || true

COPY --from=tfdocs-builder /go/bin/terraform-docs /usr/local/bin/

RUN pwsh -Command \
  Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted; \
  Install-Module -Name Az.Accounts -Force -Scope AllUsers; \
  Install-Module -Name Az.ManagedServiceIdentity -Force -Scope AllUsers; \
  Install-Module -Name Az.Resources -Force -Scope AllUsers

VOLUME ["/var/run/docker.sock"]

CMD ["pwsh"]

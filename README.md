# az-pwsh-terraform Docker Image

## Purpose

The `az-pwsh-terraform` Docker image contains Terraform, PowerShell, TFLint, Trivy, and other useful tools for managing and securing cloud infrastructure on Azure.

## Tools Included

This Docker image includes the following tools:

- **PowerShell**
- **Azure PowerShell Modules**:
  - `Az.Accounts`
  - `Az.ManagedServiceIdentity`
  - `Az.Resources`
- **Terraform**
- **Terraform-docs**: Generates Terraform module documentation automatically.
- **TFLint**: A Terraform linter that helps detect possible issues in your Terraform code.
- **Trivy**: A security scanner for container images, which helps detect vulnerabilities.
- **Newres**: A tool to automate writing the main.tf and variables.tf files using the provider schema.

## Building the Docker Image

To build the `az-pwsh-terraform` Docker image locally, follow these steps:

### Prerequisites

Ensure you have Docker installed on your machine. You can install Docker from the official Docker website: <https://www.docker.com/get-started>

### Steps to Build

1. Clone or download this repository.
2. Open a terminal and navigate to the directory where the `Dockerfile` is located.
3. Run the following command to build the image:

```bash
docker build -t az-pwsh-terraform .
```

### Testing with Docker

You can run and exec into the container using this:

```bash
docker run -it --name az-pwsh-tf az-pwsh-terraform pwsh
# remove with:
#docker container rm az-pwsh-tf --force
```

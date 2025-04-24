# az-pwsh-terraform Docker Image

## Purpose

The `az-pwsh-terraform` Docker image contains Terraform, PowerShell (with base modules for interacting with Azure), TFLint, Checkov, Trivy, and other useful tools for managing and securing cloud infrastructure on Azure.

## Tools Included

This Docker image includes the following tools:

- **PowerShell**: A cross-platform scripting language and shell for managing Azure resources.
- **Azure PowerShell Modules**:
  - `Az.Accounts`: For managing Azure account and subscription authentication.
  - `Az.ManagedServiceIdentity`: For managing Azure Managed Service Identities.
  - `Az.Resources`: For managing Azure resources.
- **Terraform**: Infrastructure as Code (IaC) tool for provisioning Azure resources.
- **Terraform-docs**: Generates Terraform module documentation automatically.
- **TFLint**: A Terraform linter that helps detect possible issues in your Terraform code.
- **Checkov**: A static code analysis tool for checking Terraform security best practices.
- **Trivy**: A security scanner for container images, which helps detect vulnerabilities.

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

# Copilot Instructions for az-pwsh-terraform Workflows

This document explains the design decisions and best practices implemented in the GitHub Actions workflows for the `az-pwsh-terraform` project. These workflows ensure a secure, efficient, and traceable CI/CD pipeline for building, scanning, and deploying Docker images.

---

## 1. **docker-pr-build-and-scan.yml**

### Purpose

This workflow is triggered on pull requests and is responsible for:

- Building the Docker image.
- Tagging the image with both the SHA and the PR number.
- Pushing the image to GitHub Container Registry (GHCR).
- Scanning the image with Trivy and posting a summary to the PR.
- Cleaning up old SHA-tagged images that are not associated with the current PR.

### Key Design Decisions

1. **Dual Tagging**:
   - The image is tagged with both the SHA and the PR number to ensure traceability and efficient cleanup.
   - Example tags: `ghcr.io/<repo>/az-pwsh-terraform:<SHA>` and `ghcr.io/<repo>/az-pwsh-terraform:pr-<PR_NUMBER>`.

2. **Trivy Integration**:
   - Trivy scans the image for vulnerabilities and provides actionable feedback directly in the PR.
   - Only the summary is posted to the PR, while detailed results are available in the Actions log.

3. **Cleanup Logic**:
   - Deletes old SHA-tagged images that are not associated with the current PR to reduce clutter in GHCR.
   - Uses the GitHub CLI (`gh`) to manage images in GHCR.

---

## 2. **docker-deploy.yml**

### Purpose

This workflow is triggered on pushes to the `main` branch and is responsible for:

- Pulling the SHA-tagged image from GHCR.
- Tagging the image as `latest` and pushing it to Docker Hub.
- Scanning the image with Trivy and uploading a SARIF file for GitHub Code Scanning.
- Cleaning up the SHA-tagged image from GHCR.

### Key Design Decisions

1. **Traceability**:
   - The workflow uses the SHA-tagged image from the PR workflow, ensuring consistency between testing and deployment.

2. **Trivy Integration**:
   - Trivy scans the image and uploads a SARIF file to the Code Scanning tab in GitHub.
   - This ensures that security vulnerabilities are tracked and visible in the repository.

3. **Cleanup Logic**:
   - Removes the SHA-tagged image from GHCR after deployment to prevent dangling images.
   - Uses the GitHub CLI (`gh`) to delete the image.

---

## 3. **docker-tag-release.yml**

### Purpose

This workflow is triggered on semantic versioning tags (e.g., `v1.2.3`) and is responsible for:

- Pulling the SHA-tagged image from GHCR.
- Tagging the image with the version and `latest` tags.
- Pushing the image to Docker Hub.
- Cleaning up the SHA-tagged image from GHCR.

### Key Design Decisions

1. **Versioned Releases**:
   - Uses semantic versioning to create versioned tags for Docker images.
   - Example tags: `ghcr.io/<repo>/az-pwsh-terraform:<SHA>` and `docker.io/<username>/az-pwsh-terraform:v1.2.3`.

2. **Traceability**:
   - Pulls the SHA-tagged image from GHCR, ensuring consistency with the tested image.

3. **Cleanup Logic**:
   - Removes the SHA-tagged image from GHCR after tagging and pushing to Docker Hub.
   - Uses the GitHub CLI (`gh`) to delete the image.

---

## General Best Practices

1. **Use of SHA for Tagging**:
   - The SHA uniquely identifies the commit that produced the image, ensuring traceability and avoiding conflicts.

2. **Efficient Cleanup**:
   - Cleanup steps are implemented in each workflow to prevent dangling images in GHCR.
   - The PR workflow retains only the latest image for a PR, while the deploy and release workflows remove the SHA-tagged image after use.

3. **Trivy Integration**:
   - Trivy is used in both the PR and deploy workflows to scan images for vulnerabilities.
   - SARIF files are uploaded to GitHub Code Scanning for visibility and tracking.

4. **Minimal Permissions**:
   - Each workflow uses the least privileges required to perform its tasks (e.g., `contents: read`, `security-events: write`, `packages: write`).

5. **Error Handling**:
   - Cleanup steps use `|| true` to ensure that workflows do not fail if an image or tag does not exist.

---

This document serves as a reference for understanding the design and implementation of the CI/CD workflows in this repository. If changes are made to the workflows, this document should be updated accordingly.

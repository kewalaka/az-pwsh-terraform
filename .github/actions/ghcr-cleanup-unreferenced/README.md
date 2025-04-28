# GHCR Cleanup Unreferenced SHAs

This GitHub Action deletes container image versions in GHCR that are only referenced by SHA tags (commit or digest), and not by any PR tag. It helps keep your registry tidy by removing unreferenced or dangling images.

## What it does

- Deletes images tagged only by commit SHA (SHA40) and not by any `pr-<number>` tag.
- Deletes images tagged only by digest (SHA256) and not created near any PR-tagged image (using a time heuristic).

## Inputs

- `token` (**required**): A GitHub token with `packages: write` permission.

## Usage

```yaml
- name: Cleanup unreferenced SHA images
  uses: ./.github/actions/ghcr-cleanup-unreferenced
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
```

## When to use

- At the end of PR build workflows to remove old, unreferenced images.
- As part of scheduled or manual cleanups to keep your registry lean.

## How it works

- Uses the GitHub CLI (`gh`) to list all container versions in the current repo's GHCR package.
- Deletes any version that:
  - Has only SHA tags and no PR tag, or
  - Is a digest-only version not created near a PR-tagged version.

## Requirements

- The GitHub Actions runner must have the GitHub CLI (`gh`) and `jq` installed (standard on Ubuntu runners).
- The action must run in a repository with a GHCR container package.

## Notes

- This action is safe to run multiple times; it only deletes truly unreferenced images.
- For PR image cleanup (removing `pr-<number>` tags), use a separate action (e.g., the deploy cleanup action).

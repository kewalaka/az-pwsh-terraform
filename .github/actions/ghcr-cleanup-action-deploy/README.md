# GHCR Cleanup Action (Deploy)

This GitHub Action deletes the PR-tagged image (e.g., `pr-<number>`) from GHCR after a successful deployment, and then calls the unreferenced SHA cleanup action to remove any leftover unreferenced images.

## What it does

- Deletes the container image version in GHCR tagged with `pr-<number>` (for the merged PR).
- Invokes the shared unreferenced SHA cleanup action to remove any commit/digest images not referenced by a PR tag.

## Inputs

- `token` (**required**): A GitHub token with `packages: write` permission.
- `pr-number` (**required**): The PR number whose image tag should be deleted.

## Usage

```yaml
- name: Remove PR image from GHCR
  uses: ./.github/actions/ghcr-cleanup-action-deploy
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    pr-number: ${{ env.PR_NUMBER }}
```

## When to use

- At the end of your deploy workflow, after promoting the PR image to Docker Hub or another registry.

## How it works

- Uses the GitHub CLI (`gh`) to find and delete the GHCR image version tagged with `pr-<number>`.
- Then calls the unreferenced SHA cleanup action to tidy up any remaining unreferenced images.

## Requirements

- The GitHub Actions runner must have the GitHub CLI (`gh`) and `jq` installed (standard on Ubuntu runners).
- The action must run in a repository with a GHCR container package.

## Notes

- This action is safe to run multiple times; it only deletes the specified PR image and unreferenced images.
- For general unreferenced SHA cleanup, use the shared action directly.

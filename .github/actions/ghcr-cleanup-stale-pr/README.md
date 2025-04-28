# GHCR Stale PR Cleanup Action

This GitHub Action removes GHCR images tagged with `pr-<number>` for pull requests that are no longer open, then runs the unreferenced SHA cleanup to tidy up any leftover images.

## What it does

- Lists all open PRs in the repository.
- Deletes any GHCR image version tagged with `pr-<number>` where `<number>` is not an open PR.
- Invokes the shared unreferenced SHA cleanup action to remove any commit/digest images not referenced by a PR tag.

## Inputs

- `token` (**required**): A GitHub token with `packages: write` permission.

## Usage

```yaml
- name: Remove stale PR images & tidy SHAs
  uses: ./.github/actions/ghcr-cleanup-stale-pr
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
```

## When to use

- On a schedule (e.g., nightly) to keep your registry free of images for closed PRs and unreferenced SHAs.

## How it works

- Uses the GitHub CLI (`gh`) to list open PRs and all container versions in the current repo's GHCR package.
- Deletes any version with a `pr-<number>` tag not in the open PR list.
- Then calls the unreferenced SHA cleanup action.

## Requirements

- The GitHub Actions runner must have the GitHub CLI (`gh`) and `jq` installed (standard on Ubuntu runners).
- The action must run in a repository with a GHCR container package.

## Notes

- This action is safe to run multiple times; it only deletes PR images for closed PRs and unreferenced images.
- For general unreferenced SHA cleanup, use the shared action directly.

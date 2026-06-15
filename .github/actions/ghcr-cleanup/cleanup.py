import json
import os
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime


TOLERANCE_SECONDS = 10


def log(message: str) -> None:
    print(message, flush=True)


def api_request(url: str, *, method: str = "GET") -> tuple[int, object | None]:
    request = urllib.request.Request(
        url=url,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}",
            "X-GitHub-Api-Version": "2022-11-28",
        },
        method=method,
    )
    try:
        with urllib.request.urlopen(request) as response:
            status = response.getcode()
            payload = response.read()
            if not payload:
                return status, None
            return status, json.loads(payload)
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return 404, None
        detail = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {url} failed with HTTP {error.code}: {detail}") from error


def owner_type(owner: str) -> str:
    api_url = os.environ["GITHUB_API_URL"]
    _, payload = api_request(f"{api_url}/users/{owner}")
    return str(payload["type"]) if isinstance(payload, dict) and "type" in payload else "User"


def package_versions(package_url: str) -> list[dict]:
    versions: list[dict] = []
    page = 1
    while True:
        query = urllib.parse.urlencode({"per_page": 100, "page": page})
        _, payload = api_request(f"{package_url}/versions?{query}")
        page_versions = payload if isinstance(payload, list) else []
        if not page_versions:
            break
        versions.extend(page_versions)
        if len(page_versions) < 100:
            break
        page += 1
    return versions


def tags_for(version: dict) -> list[str]:
    metadata = version.get("metadata") or {}
    container = metadata.get("container") or {}
    tags = container.get("tags") or []
    return [str(tag) for tag in tags]


def has_pr_tag(version: dict) -> bool:
    return any(tag.startswith("pr-") and tag[3:].isdigit() for tag in tags_for(version))


def has_sha40_tag(version: dict) -> bool:
    return any(len(tag) == 40 and all(ch in "0123456789abcdef" for ch in tag) for tag in tags_for(version))


def parse_timestamp(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def has_nearby_pr_tag(version: dict, pr_versions: list[dict]) -> bool:
    created_at = version.get("created_at")
    if not created_at:
        return False

    created = parse_timestamp(str(created_at))
    for pr_version in pr_versions:
        pr_created_at = pr_version.get("created_at")
        if not pr_created_at:
            continue
        diff = abs((created - parse_timestamp(str(pr_created_at))).total_seconds())
        if diff <= TOLERANCE_SECONDS:
            return True
    return False


def delete_version(package_url: str, version_id: int | str) -> None:
    delete_url = f"{package_url}/versions/{version_id}"
    try:
        api_request(delete_url, method="DELETE")
        log(f"Deleted version {version_id}")
    except RuntimeError as error:
        log(f"Failed to delete {version_id}: {error}")


def main() -> int:
    repo = os.environ["GITHUB_REPOSITORY"]
    owner, package = repo.split("/", 1)
    api_url = os.environ["GITHUB_API_URL"]
    cleanup_mode = os.environ["CLEANUP_MODE"]
    pr_number = os.environ.get("PR_NUMBER")

    if cleanup_mode == "deploy" and not pr_number:
        raise RuntimeError("PR_NUMBER is required when CLEANUP_MODE=deploy")

    if owner_type(owner) == "Organization":
        package_url = f"{api_url}/orgs/{owner}/packages/container/{package}"
    else:
        package_url = f"{api_url}/user/packages/container/{package}"

    status, _ = api_request(package_url)
    if status == 404:
        log("Package not found")
        return 0

    log(f"Checking for packages to cleanup at: {package_url}")
    versions = package_versions(package_url)
    pr_versions = [version for version in versions if has_pr_tag(version)]
    deleted_ids: set[int | str] = set()

    def delete_once(version_id: int | str) -> None:
        if version_id in deleted_ids:
            return
        delete_version(package_url, version_id)
        deleted_ids.add(version_id)

    if cleanup_mode == "deploy":
        explicit_tag = f"pr-{pr_number}"
        log(f"Deleting explicit PR image with tag {explicit_tag}")
        for version in versions:
            if explicit_tag in tags_for(version):
                delete_once(version["id"])

    log("Deleting orphaned SHA40 images")
    for version in versions:
        if has_sha40_tag(version) and not has_pr_tag(version):
            delete_once(version["id"])

    log(f"Looking for orphaned SHA256 tags (tolerance = {TOLERANCE_SECONDS} seconds)")
    for version in versions:
        version_id = version["id"]
        tags = tags_for(version)

        if has_pr_tag(version):
            log(f"Skipping version {version_id}: has friendly tag(s): {' '.join(tags)}")
            continue

        if has_nearby_pr_tag(version, pr_versions):
            log(
                f"Skipping version {version_id}: nearby PR tag exists "
                f"(created at {version.get('created_at')})"
            )
            continue

        log(
            f"Deleting version {version_id} (created at {version.get('created_at')}): "
            "no recent PR tag detected"
        )
        delete_once(version_id)

    log("Cleanup complete.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        log(str(error))
        raise

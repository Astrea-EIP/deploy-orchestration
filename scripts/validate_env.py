import os
import re
import sys
import time

import requests
import yaml
from requests.exceptions import RequestException

GITHUB_API_URL_BASE = "https://api.github.com"
GITHUB_SESSION = requests.Session()

GITHUB_HEADERS = {
    "Accept": "application/vnd.github+json",
}

_token = os.environ.get("GITHUB_TOKEN")
if _token:
    GITHUB_HEADERS["Authorization"] = f"Bearer {_token}"

GITHUB_SESSION.headers.update(GITHUB_HEADERS)

LAST_REQUEST_TIME = 0.0
RATE_LIMIT_INTERVAL = 0.2
SEMVER_TAG_PATTERN = re.compile(r"^v\d+\.\d+\.\d+$")


def check_tag(repo, tag):
    global LAST_REQUEST_TIME
    url = f"{GITHUB_API_URL_BASE}/repos/{repo}/git/ref/tags/{tag}"

    now = time.time()
    elapsed = now - LAST_REQUEST_TIME
    if elapsed < RATE_LIMIT_INTERVAL:
        time.sleep(RATE_LIMIT_INTERVAL - elapsed)

    try:
        response = GITHUB_SESSION.get(url, timeout=10)
    except RequestException as e:
        print(f"⚠️ Network error: {e}")
        return False

    LAST_REQUEST_TIME = time.time()
    return response.status_code == 200


def validate(file):
    with open(file, "r") as f:
        data = yaml.safe_load(f)

    errors = []

    if "environment" not in data:
        errors.append("Missing environment field")

    if "services" not in data:
        errors.append("Missing services")

    for name, service in data.get("services", {}).items():
        repo = service.get("repo")
        version = service.get("version")

        if not repo or not version:
            errors.append(f"{name}: missing repo or version")
            continue

        if not SEMVER_TAG_PATTERN.match(version):
            errors.append(f"{name}: version must match vX.Y.Z")
            continue

        if not check_tag(repo, version):
            errors.append(f"{name}: invalid version tag {version}")

    if errors:
        print("❌ Validation failed:")
        for e in errors:
            print(f"- {e}")
        sys.exit(1)

    print(f"✅ {file} is valid")


if __name__ == "__main__":
    validate(sys.argv[1])

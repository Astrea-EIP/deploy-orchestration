"""Reads an environments/<name>.yml file and writes a .env file mapping each
service's version to the image tags consumed by docker-compose.prod.yml.

Usage: python scripts/render_env.py environments/preprod.yml > .env
"""

import sys

import yaml

# Maps a service name in environments/*.yml to the .env variable consumed by
# docker-compose.prod.yml. core-moteur is tagged and published as a single
# unit (lib/ and graphhopper/ share the same version), so its version also
# drives the graphhopper image.
ENV_VAR_BY_SERVICE = {
    "app-web": "APP_WEB_VERSION",
    "api-back": "API_BACK_VERSION",
    "core-moteur": "GRAPHHOPPER_VERSION",
}


def render(file):
    with open(file, "r") as f:
        data = yaml.safe_load(f)

    lines = []
    for name, env_var in ENV_VAR_BY_SERVICE.items():
        service = data.get("services", {}).get(name)
        if not service or not service.get("version"):
            print(f"Missing version for {name} in {file}", file=sys.stderr)
            sys.exit(1)
        lines.append(f"{env_var}={service['version']}")

    print("\n".join(lines))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python scripts/render_env.py environments/<name>.yml", file=sys.stderr)
        sys.exit(1)
    render(sys.argv[1])

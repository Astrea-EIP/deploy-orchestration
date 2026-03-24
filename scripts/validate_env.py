import yaml
import requests
import sys

def check_commit(repo, ref):
    url = f"https://api.github.com/repos/{repo}/commits/{ref}"
    response = requests.get(url)
    return response.status_code == 200

def validate(file):
    with open(file, "r") as f:
        data = yaml.safe_load(f)

    if "services" not in data:
        print("❌ Missing 'services'")
        sys.exit(1)

    errors = []

    for name, service in data["services"].items():
        repo = service.get("repo")
        ref = service.get("ref")

        if not repo or not ref:
            errors.append(f"{name}: missing repo or ref")
            continue

        if not check_commit(repo, ref):
            errors.append(f"{name}: invalid ref {ref}")

    if errors:
        print("❌ Validation failed:")
        for e in errors:
            print(f"- {e}")
        sys.exit(1)

    print(f"✅ {file} is valid")

if __name__ == "__main__":
    validate(sys.argv[1])
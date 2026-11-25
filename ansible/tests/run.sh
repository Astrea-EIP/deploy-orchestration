#!/usr/bin/env bash
# Checks ansible/server-setup.yml without touching any real server:
#   1. ansible-playbook --syntax-check and ansible-lint
#   2. first run on a fresh Ubuntu 24.04 container (systemd): must succeed
#   3. second run: must report changed=0
#   4. the resulting state (Docker, Compose, deploy user, keys, firewall,
#      deployment directory) and that a hand-written .env.secrets is untouched
#
# Needs Docker on the machine, plus ansible-core, ansible-lint and the
# collections from ansible/requirements.yml (see docs/server-setup.md).
set -euo pipefail

cd "$(dirname "$0")/.."

CONTAINER=astrea-ansible-test
IMAGE=astrea-ansible-test:ubuntu-24.04
INVENTORY=tests/inventory.yml
DEPLOY_DIR=/srv/astrea-test
LOG_DIR=$(mktemp -d)

cleanup() {
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup EXIT

step() { printf '\n==> %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
in_target() { docker exec "$CONTAINER" bash -c "$1"; }

# Prints the "changed=N" value of the PLAY RECAP line of a run log.
recap_changed() {
    grep -E '^astrea-test +:' "$1" | sed -E 's/.*changed=([0-9]+).*/\1/'
}

step "Syntax check"
ansible-playbook -i "$INVENTORY" server-setup.yml --syntax-check

step "ansible-lint"
ansible-lint server-setup.yml

step "Start a fresh Ubuntu 24.04 container"
cleanup
docker build -q -t "$IMAGE" tests/ >/dev/null
# --privileged and a dedicated volume for /var/lib/docker are needed so that
# Docker and ufw can run inside the container.
docker run -d --name "$CONTAINER" --privileged --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    --tmpfs /run --tmpfs /run/lock \
    --mount type=volume,dst=/var/lib/docker \
    "$IMAGE" >/dev/null
for _ in $(seq 30); do
    state=$(in_target 'systemctl is-system-running 2>/dev/null || true')
    [[ $state == running || $state == degraded ]] && break
    sleep 1
done

step "First run"
ANSIBLE_FORCE_COLOR=0 ansible-playbook -i "$INVENTORY" server-setup.yml \
    | tee "$LOG_DIR/run1.log"
echo "first run: changed=$(recap_changed "$LOG_DIR/run1.log")"

step "Write .env.secrets by hand, as the procedure says"
in_target "umask 077 && printf 'Jwt__SigningKey=test-sentinel\n' > $DEPLOY_DIR/.env.secrets \
    && chown deploy:deploy $DEPLOY_DIR/.env.secrets"
secrets_before=$(in_target "sha256sum $DEPLOY_DIR/.env.secrets; stat -c '%a %U' $DEPLOY_DIR/.env.secrets")

step "Second run (must change nothing)"
ANSIBLE_FORCE_COLOR=0 ansible-playbook -i "$INVENTORY" server-setup.yml \
    | tee "$LOG_DIR/run2.log"
changed=$(recap_changed "$LOG_DIR/run2.log")
echo "second run: changed=$changed"
[[ $changed == 0 ]] || fail "second run changed $changed task(s), the playbook is not idempotent"

step "Check the resulting state"
in_target 'systemctl is-active docker' >/dev/null || fail "docker service is not active"
in_target 'systemctl is-enabled docker' >/dev/null || fail "docker service is not enabled"
compose=$(in_target 'docker compose version --short')
echo "docker compose $compose"
# env_file with path/required (docker-compose.prod.yml) needs Compose >= 2.24.
printf '2.24.0\n%s\n' "$compose" | sort -V -C || fail "docker compose $compose is older than 2.24"
in_target 'id -nG deploy' | grep -qw docker || fail "deploy is not in the docker group"
in_target 'su - deploy -c "docker info >/dev/null"' || fail "deploy cannot use docker"
in_target 'grep -q astrea-test-only ~deploy/.ssh/authorized_keys' || fail "member key missing"
[[ $(in_target 'stat -c "%a %U" ~deploy/.ssh/authorized_keys') == "600 deploy" ]] \
    || fail "authorized_keys has wrong mode or owner"
[[ $(in_target "stat -c '%a %U %G' $DEPLOY_DIR") == "750 deploy deploy" ]] \
    || fail "deployment directory has wrong mode or owner"
ufw=$(in_target 'ufw status verbose')
echo "$ufw"
grep -q 'Status: active' <<<"$ufw" || fail "ufw is not active"
grep -q 'Default: deny (incoming)' <<<"$ufw" || fail "ufw does not deny incoming by default"
# Every ALLOW IN rule (IPv4 and IPv6) must be one of 22, 80 or 443/tcp.
opened=$(grep -E 'ALLOW IN' <<<"$ufw" | awk '{print $1}' | sort -u | tr '\n' ' ')
[[ $opened == "22/tcp 443/tcp 80/tcp " ]] \
    || fail "ufw allows '$opened' instead of 22, 80 and 443/tcp only"
secrets_after=$(in_target "sha256sum $DEPLOY_DIR/.env.secrets; stat -c '%a %U' $DEPLOY_DIR/.env.secrets")
[[ $secrets_before == "$secrets_after" ]] || fail ".env.secrets was modified by the playbook"

printf '\nOK: syntax, lint, first run, second run changed=0, final state checked.\n'

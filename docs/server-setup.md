# Server setup (Ansible)

`ansible/server-setup.yml` prepares a fresh server for an Astrea deployment in
one command (#25). It is meant to run once on a new VM (#16), and again at any
time: a second run changes nothing.

## What it does

- Checks the target is Ubuntu 24.04 on x86_64 (GHCR images are amd64 only).
- Installs Docker Engine and the Compose plugin from Docker's official apt
  repository (`docker-compose.prod.yml` needs Compose 2.24 or later), and
  starts Docker at boot.
- Creates the `deploy` user, in the `docker` group, and adds the members' SSH
  public keys to its `authorized_keys`.
- Turns on `ufw`: incoming connections denied except 22, 80 and 443/tcp.
- Creates the deployment directory, owned by `deploy`, mode `0750`.

It never creates, reads or overwrites `.env.secrets`: that file is written by
hand on the server (see the README, "Token signing key"). The playbook only
reports whether it is missing or has the wrong mode or owner.

It does not clone the repository, log in to GHCR, or start the stack: that is
the deployment's job (#18).

## Running it

From a team machine, with Python 3:

```bash
python3 -m venv .venv
.venv/bin/pip install -r ansible/requirements.txt
.venv/bin/ansible-galaxy collection install -r ansible/requirements.yml
cp ansible/inventory.example.yml ansible/inventory.yml   # not committed
# fill in ansible/inventory.yml, then:
.venv/bin/ansible-playbook -i ansible/inventory.yml ansible/server-setup.yml
```

The first run connects with the account the VM image provides (with `sudo`),
since `deploy` does not exist yet. Once the playbook has run, members connect
with `ssh deploy@<server>`.

## Inventory variables

| Variable | Required | Meaning |
| --- | --- | --- |
| `astrea_deploy_dir` | yes | Absolute path of the deployment directory on the server (where `docker-compose.prod.yml`, `.env` and `.env.secrets` live). |
| `astrea_ssh_authorized_keys` | yes | List of public keys allowed to log in as `deploy`: one per member, later the CI deploy key (#18). |
| `astrea_deploy_user` | no | Defaults to `deploy`. |

The playbook stops before changing anything if a required variable is missing.
Keys are only ever added: removing a member means deleting their line from
`~deploy/.ssh/authorized_keys` on the server.

## Firewall and Docker

Docker writes its own iptables rules for published ports, and those bypass
`ufw`. A port published by a compose file (`ports:`) is reachable from outside
even though `ufw` denies it. `ufw` alone therefore does not guarantee "22, 80
and 443 only": `docker-compose.prod.yml` must publish nothing but the reverse
proxy's 80 and 443 (planned in #18; today it still publishes 27017, 8989, 5217
and 4200).

## Testing the playbook

`ansible/tests/run.sh` runs `--syntax-check`, `ansible-lint`, then the playbook
twice on a throwaway Ubuntu 24.04 container with systemd, fails if the second
run reports any change, and checks the resulting state (including that a
hand-written `.env.secrets` is left untouched). It needs Docker and the tools
above:

```bash
PATH="$PWD/.venv/bin:$PATH" ansible/tests/run.sh
```

The container is not a real VM: SSH login as `deploy`, reaching 80/443 from
outside, and behaviour after a reboot are not covered by this test.

# Disposable Ubuntu 24.04 target with systemd, close to a fresh cloud VM, used
# only by ansible/tests/run.sh. Not a deployment image.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# What a stock Ubuntu cloud image already has (systemd, python3, sudo, CA
# certificates). Docker, ufw and the deploy user are left to the playbook.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        systemd systemd-sysv python3 python3-apt sudo ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]

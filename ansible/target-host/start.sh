#!/usr/bin/env bash
# (Re)creates the Ansible target container "bu-ansible-target":
# Ubuntu 24.04 + real systemd + sshd, SSH on host :2222, app on host :18081.
# Safe to re-run: it removes only the container with this exact name.
set -euo pipefail

NAME=bu-ansible-target
IMAGE=bu-ansible-target:24.04
KEY="${BU_ANSIBLE_KEY:-$HOME/.ssh/bu-ansible-demo}"
SSH_PORT="${SSH_PORT:-2222}"
APP_PORT_HOST="${APP_PORT_HOST:-18081}"
HERE="$(cd "$(dirname "$0")" && pwd)"

# Demo key pair lives outside the repo; never commit the private key.
if [[ ! -f "$KEY" ]]; then
  ssh-keygen -t ed25519 -N "" -C "bu-ansible-demo" -f "$KEY"
fi

docker build -t "$IMAGE" "$HERE"

docker rm -f "$NAME" >/dev/null 2>&1 || true

# systemd as PID 1 needs: privileged, host cgroup namespace, writable cgroup
# mount, and tmpfs on /run. SIGRTMIN+3 (set in the Dockerfile) stops it cleanly.
docker run -d --name "$NAME" \
  --privileged --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --tmpfs /run --tmpfs /run/lock --tmpfs /tmp \
  -p "${SSH_PORT}:22" -p "${APP_PORT_HOST}:8081" \
  "$IMAGE" >/dev/null

# Wait until systemd reports it is up (running or degraded).
for _ in $(seq 1 60); do
  state="$(docker exec "$NAME" systemctl is-system-running 2>/dev/null || true)"
  [[ "$state" == "running" || "$state" == "degraded" ]] && break
  sleep 1
done
echo "systemd state: ${state:-unknown}"

# Install the public key for the login user.
docker cp "${KEY}.pub" "$NAME:/home/deployer/.ssh/authorized_keys"
docker exec "$NAME" chown deployer:deployer /home/deployer/.ssh/authorized_keys
docker exec "$NAME" chmod 0600 /home/deployer/.ssh/authorized_keys

echo "ready: ssh -i $KEY -p $SSH_PORT deployer@127.0.0.1"

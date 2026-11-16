# Ansible target: Ubuntu 24.04 with real systemd as PID 1 and an SSH server.
# Behaves like a small VM so the playbook can use the normal systemd module.
FROM ubuntu:24.04

ENV container=docker \
    DEBIAN_FRONTEND=noninteractive

# python3 is required on the managed host by Ansible modules.
# sudo lets the unprivileged "deployer" login escalate (become: true).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      systemd systemd-sysv dbus openssh-server python3 sudo curl ca-certificates iproute2 \
 && rm -rf /var/lib/apt/lists/*

# Remove units that make no sense inside a container or that fail without
# real hardware (they only add noise and slow boot).
RUN find /etc/systemd/system /lib/systemd/system \
      \( -path '*.wants/*' -o -path '*.requires/*' \) \
      \( -name '*getty*' -o -name '*systemd-udev*' -o -name '*systemd-remount-fs*' \
         -o -name '*sys-kernel*' -o -name '*systemd-update-utmp*' \) \
      -delete \
 && systemctl mask getty.target console-getty.service systemd-udevd.service \
      systemd-udev-trigger.service systemd-remount-fs.service

# Login user for Ansible: key-only SSH, passwordless sudo.
RUN useradd --create-home --shell /bin/bash deployer \
 && echo 'deployer ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/deployer \
 && chmod 0440 /etc/sudoers.d/deployer \
 && install -d -m 0700 -o deployer -g deployer /home/deployer/.ssh \
 && mkdir -p /run/sshd \
 && printf 'PasswordAuthentication no\nPermitRootLogin no\nUsePAM yes\n' > /etc/ssh/sshd_config.d/10-demo.conf \
 && systemctl enable ssh.service

EXPOSE 22 8081

# systemd shuts down cleanly on SIGRTMIN+3.
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]

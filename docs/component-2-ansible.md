# Component 2, part 1: Ansible deploys the JAR as a systemd service (DEVOPS-02)

Ansible installs Java on a target host, copies the Gradle-built JAR of the Better University Campus API,
installs a systemd unit and checks `/health`. Evidence is in `evidence/component-2/ansible/`.

## Layout

```
ansible/
  ansible.cfg            inventory path, roles path, no host-key prompt
  inventory.ini          group campus_api -> 127.0.0.1:2222, user deployer, demo key
  playbook.yml           one play that applies the role
  roles/bu_campus_api/   made with `ansible-galaxy init roles/bu_campus_api`
  target-host/           Dockerfile + start.sh for the systemd target container
```

## The target host

Ansible needs a machine reachable over SSH that runs systemd. A normal container does not run systemd,
so `ansible/target-host/Dockerfile` builds an Ubuntu 24.04 image where `/sbin/init` (systemd) is PID 1
and `openssh-server` is enabled. `start.sh` runs it on the Colima Docker as `bu-ansible-target`:

| Setting | Why |
|---|---|
| `--privileged --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw` | systemd must manage cgroups (cgroup v2 on Colima) |
| `--tmpfs /run --tmpfs /run/lock --tmpfs /tmp` | systemd expects these to be tmpfs |
| `STOPSIGNAL SIGRTMIN+3` | the signal systemd treats as a clean shutdown |
| `-p 2222:22` | SSH from the Mac |
| `-p 18081:8081` | the app (`app_port` 8081 inside) reachable from the Mac |
| masked getty/udev/remount-fs units | they only fail without hardware |
| user `deployer`, key-only SSH, passwordless sudo | Ansible logs in as a normal user and uses `become` |

The key pair is `~/.ssh/bu-ansible-demo` (ed25519, created by `start.sh` if missing, outside the repo).
Only the public key is copied into the container. Verification: `ps -p 1` shows `systemd`
and `systemctl status bu-campus-api` works (`07-systemctl-status`).

## Why each Ansible piece

- **Role (`bu_campus_api`)**: keeps the deploy logic reusable and separate from the play; the playbook
  only says which hosts and which values. The generated structure (`defaults`, `vars`, `tasks`,
  `handlers`, `templates`, `meta`, `tests`, `files`) is kept.
- **Variables**: `app_port` (8081), `app_version`, `app_user`, `app_dir` and `jar_src` live in
  `defaults/main.yml` so any of them can be overridden from the playbook, inventory or `-e`.
  `vars/main.yml` holds constants of the role (service name, JDK package, destination paths).
  `app_version` selects `build/libs/bu-campus-api-<version>-all.jar`, is written to
  `/etc/default/bu-campus-api` as `APP_VERSION` and is what `/health` returns, so the upgrade run
  proves the new JAR is live.
- **Templates**: the unit file (`bu-campus-api.service.j2`) uses `EnvironmentFile=` pointing at a second
  template (`PORT`, `APP_VERSION`), so port and version come from variables instead of being hard-coded.
- **Handlers**: `restart bu-campus-api` is notified only by the tasks that copy the JAR, write the env file
  or write the unit; `daemon reload` is notified by the unit task. A handler runs only if one of those
  reported `changed`, so an unchanged re-run never restarts the service. `meta: flush_handlers` runs
  them before the enable/start and health check tasks instead of at the end of the play.
- **Idempotence**: apt `present`, user/group/file/copy/template and `systemd_service` are all
  state-based. The `/health` check has `changed_when: false` so it never counts as a change.
- **Health check**: `uri` with `retries`/`until` waits for the JVM to start (up to 15 x 2 s).

## How to rerun

```bash
./ansible/target-host/start.sh            # (re)create the target container
./gradlew build -PappVersion=1.0.0        # JAR for the role
cd ansible
ansible -i inventory.ini campus_api -m ping
ansible-playbook -i inventory.ini playbook.yml --syntax-check
ansible-playbook -i inventory.ini playbook.yml                       # first run: changes
ansible-playbook -i inventory.ini playbook.yml                       # second run: changed=0
cd .. && ./gradlew build -PappVersion=1.1.0 && cd ansible
ansible-playbook -i inventory.ini playbook.yml -e app_version=1.1.0   # new JAR: handler fires
curl http://127.0.0.1:18081/health
```

## Results

| Run | PLAY RECAP | Handler |
|---|---|---|
| First (fresh host) | `ok=13 changed=9 failed=0` | fired |
| Second (same inputs) | `ok=11 changed=0 failed=0` | not run |
| New JAR, `app_version=1.1.0` | `ok=13 changed=4 failed=0` | fired; `/health` reports 1.1.0 |
| Again with 1.1.0 | `ok=11 changed=0 failed=0` | not run |

`changed=4` in the upgrade run is the JAR, the env file, the unit file (its `Description` contains the
version) and the restart handler.

## Problems hit and fixes

- **systemd in a container** (the failure in the reference report): it worked on the first attempt with
  the flags in the table above (privileged, host cgroup namespace, writable `/sys/fs/cgroup`, tmpfs on
  `/run`, `/sbin/init` as PID 1). `systemctl is-system-running` returned `running`.
- **`daemon reload` shows `ok`, not `changed`**: `systemd_service` with `daemon_reload` does not report a
  change, even though it ran. The `RUNNING HANDLER` line is the evidence.
- **Slow first run**: installing the JDK inside the container took about two minutes (see the
  task timings in `03-first-run.log`). Later runs skip it (`cache_valid_time`, package present).
- **Capture glitches (not product bugs)**: my first `systemctl status` capture contained terminal
  hyperlink escape codes from systemd; I re-ran it with `SYSTEMD_URLIFY=0`. An ad-hoc `ssh` used for the
  capture first failed with `Host key verification failed` until `StrictHostKeyChecking=no`
  was added. The ansible runs themselves needed no retries.
- **Limitations**: the target is a privileged container on the same Mac, not a separate VM; the
  container's host key changes when it is recreated (so the inventory uses `/dev/null` as known_hosts and
  `ansible.cfg` disables host-key checking); the private demo key is not in the repository, so the
  container must be created with `start.sh` on the machine that runs Ansible.

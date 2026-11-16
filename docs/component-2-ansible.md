# Component 2, part 1: Ansible deploys the JAR as a systemd service (DEVOPS-02)

Ansible installs Java on a target host, copies the Gradle-built JAR of the Better University Campus API,
installs a systemd unit and checks `/health`. Evidence is in `evidence/component-2/ansible/`.

## Layout

```
ansible/
  ansible.cfg            inventory path, roles path
  inventory.ini          group campus_api -> host hospet (127.0.0.1) over SSH, user nawaab, demo key
  playbook.yml           one play (become: true) that applies the role
  roles/bu_campus_api/   made with `ansible-galaxy init roles/bu_campus_api`
```

## The target host

The target is the VM `hospet` (Ubuntu 25.10, real systemd as PID 1) itself. It is managed over SSH, not with
`ansible_connection=local`, so the run is the same as for a remote server:

```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/bu-ansible-demo        # private key never committed
cat ~/.ssh/bu-ansible-demo.pub >> ~/.ssh/authorized_keys
```

`inventory.ini` has `hospet ansible_host=127.0.0.1 ansible_user=nawaab
ansible_ssh_private_key_file=~/.ssh/bu-ansible-demo` in group `campus_api`. The user has passwordless sudo,
so `become: true` works. The service listens on port 8081 (`app_port`), because Jenkins uses 8080.
The earlier Mac/Docker systemd container (`ansible/target-host/`) was removed; it remains in git history.

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
./gradlew build -PappVersion=1.0.0        # JAR for the role
cd ansible
ansible -i inventory.ini campus_api -m ping
ansible-playbook -i inventory.ini playbook.yml --syntax-check
ansible-playbook -i inventory.ini playbook.yml                       # first run: changes
ansible-playbook -i inventory.ini playbook.yml                       # second run: changed=0
cd .. && ./gradlew build -PappVersion=1.1.0 && cd ansible
ansible-playbook -i inventory.ini playbook.yml -e app_version=1.1.0   # new JAR: handler fires
curl http://127.0.0.1:8081/health
```

## Results (real recaps from `hospet`)

| Run | PLAY RECAP | Handler |
|---|---|---|
| First | `ok=13 changed=8 failed=0` | fired (`daemon reload`, `restart bu-campus-api`) |
| Second (same inputs) | `ok=11 changed=0 failed=0` | not run |
| New JAR, `app_version=1.1.0` | `ok=13 changed=4 failed=0` | fired; `/health` reports 1.1.0 |
| Again with 1.1.0 | `ok=11 changed=0 failed=0` | not run |

In the first run the JDK task is `ok`, not `changed`, because openjdk-17 was already on the VM; the 8 changes
are the group, user, directory, JAR, env file, unit, the restart handler and enabling the service.
`changed=4` in the upgrade run is the JAR, the env file, the unit file (its `Description` contains the
version) and the restart handler. The two idempotent runs show `changed=0` and no `RUNNING HANDLER`
line: Ansible compares desired state with the host and does nothing when they match.

The service is left running on 8081 (`systemctl status bu-campus-api`, version 1.1.0).

## Problems hit and fixes

- **Repo git config**: `.git/config` of the main clone had `user.name=user.email` (a typo). Commits for this
  work override the author with `GIT_AUTHOR_NAME`/`GIT_COMMITTER_NAME` instead of editing shared config.
- **`daemon reload` shows `ok`, not `changed`**: `systemd_service` with `daemon_reload` does not report a
  change even though it ran. The `RUNNING HANDLER` line is the evidence.
- **Port clash avoided**: 8080 belongs to Jenkins on this VM, hence `app_port: 8081`.
- **Capture details**: `SYSTEMD_URLIFY=0 SYSTEMD_COLORS=0` keep hyperlink escape codes out of the
  `systemctl` log. My first timetable request used section `A`, which returns the 404
  `no timetable for section A` (kept in `08-curl-api.log`); the valid section `CY-5A` is in `08b`.
- **Limitations**: the target is the control machine itself (SSH to 127.0.0.1), not a separate server; the
  private demo key is not in the repository, so the key pair must be generated on the machine that runs
  Ansible; the POSTed announcement is in memory only.

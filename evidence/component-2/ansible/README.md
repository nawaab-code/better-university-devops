# Component 2: Ansible evidence (VM `hospet`)

Every `.log` is raw, unedited output (ANSI colours kept, `ANSIBLE_FORCE_COLOR=1`) with a `date; hostname`
header, captured from `ansible/` on the VM `hospet`. The target is the same VM, managed over SSH
(`ansible_host=127.0.0.1`, user `nawaab`, key `~/.ssh/bu-ansible-demo`, `become: true`). Each `.png` is a
`freeze` render (dracula) of the log or source file with the same number. The earlier Mac/container evidence
is only in git history.

| File | What it proves |
|---|---|
| `00-ansible-version.log/.png` | Ansible version, config file `ansible/ansible.cfg`, Python on `hospet` |
| `01-ping.log/.png` | `ansible -m ping` reaches `hospet` over SSH with key auth: `pong` |
| `02-syntax-check.log/.png` | `ansible-playbook --syntax-check` passes |
| `02b-inventory-graph.log/.png` | `ansible-inventory --graph`: group `campus_api` contains `hospet` |
| `03-first-run.log/.png` | First run: `ok=13 changed=8`; group, user, dir, JAR, env file, unit created; handlers `daemon reload` and `restart bu-campus-api` run; service enabled; `/health` 200, version 1.0.0. The JDK task is `ok` because openjdk-17 was already installed on this VM |
| `04-second-run-idempotent.log/.png` | Second run: `ok=11 changed=0`, no `RUNNING HANDLER` lines: idempotent, handler did not fire |
| `05-new-version-run.log/.png` | After `./gradlew build -PappVersion=1.1.0`, run with `-e app_version=1.1.0`: `changed=4` (JAR, env file, unit, restart handler); `/health` reports 1.1.0 |
| `06-third-run-idempotent-after-upgrade.log/.png` | Same inputs again: `changed=0`, no handler |
| `07-systemctl-status.log/.png` | `systemctl status bu-campus-api`: `active (running)`, `enabled`, PID 1 is systemd, env file content |
| `07b-journalctl.log/.png` | `journalctl -u bu-campus-api -n 20`: service starts and listens on 0.0.0.0:8081 |
| `08-curl-api.log/.png` | curl on port 8081: `/health`, GET announcements, POST announcement (201), GET again |
| `08b-curl-timetable.log/.png` | GET `/api/v1/timetable/CY-5A` |
| `09-role-tree.txt/.png` | `tree ansible/roles`: structure from `ansible-galaxy init` |
| `10-playbook.png` | `playbook.yml` |
| `11-handlers.png` | `handlers/main.yml` |
| `12-systemd-unit-template.png` | `templates/bu-campus-api.service.j2` |
| `13-tasks.png` | `tasks/main.yml` with the `notify:` lines |
| `14-defaults.png` | `defaults/main.yml` (`app_port`, `app_version`, `app_user`, `app_dir`, `jar_src`) |
| `15-inventory.png` | `inventory.ini` |

Note: the `daemon reload` handler shows `ok`, not `changed`: that is how `systemd_service` reports
`daemon_reload`; the `RUNNING HANDLER` line shows it ran. The POST in `08` writes to in-memory data that
resets when the service restarts.

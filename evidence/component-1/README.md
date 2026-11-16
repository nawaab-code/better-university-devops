# Component 1 evidence (Git + Gradle + Jenkins CI)

All files are real captures from the VM `hospet` (Jenkins 2.580.2, Ubuntu 25.10), taken 2026-11-16.
`local-run.log` is the earlier run on the Mac (kept); `terminal/local-run-mac.png` is a render of it.

## terminal/ (raw `.log` + `freeze` `.png`)
| File | Proves |
|------|--------|
| `tool-versions` | git, JDK 21 (Jenkins), JDK 17 (builds), Gradle 8.13, OS, Jenkins 2.580.2, systemd JAVA_HOME/CASC settings |
| `git-log-graph` | `git log --graph --oneline --decorate --all`: feature branches and merge commits |
| `git-branch-a` | `git branch -a` |
| `gradle-build-vm` | `./gradlew clean build` on the VM: 4 tests passed, `bu-campus-api-vm-local-all.jar` |
| `curl-endpoints-vm` | the JAR run on port 8090: /health, GET/POST announcements, timetable, 404 (then stopped) |

## jenkins-logs/ (raw text from Jenkins)
`build-1..4-console.log` full console output (#1 manual, #2-#4 "Started by an SCM change"), `job-config.xml` job definition (SCM, branch, pollSCM, script path),
`scm-polling-tail.log` Jenkins' SCM polling log.

## screenshots/ (Playwright, 1440 px wide)
| File | Shows |
|------|-------|
| `01-job-main-stage-view` | job page: stage view, versioned JARs, test trend |
| `02`, `03` | build #2 and #4 pages: "Started by an SCM change", display name with version |
| `04`/`06`, `05`/`07` | console of build #2 / #4: top (SCM cause) and bottom (archiving, `Finished: SUCCESS`) |
| `08`, `09` | archived artifact list (`bu-campus-api-4-8014664-all.jar`, `...2-45b31c9...`) |
| `10`, `11` | test result pages, 4 tests passing |
| `12` | changes of build #4 |
| `13` | SCM polling log page |
| `14`, `15` | Jenkins About (2.580.2) and dashboard |
| `16` | job `config.xml` viewed anonymously |
| `20`, `21`, `22`, `24` | configure page (as admin): general, Poll SCM `* * * * *`, Pipeline from SCM + repo URL, branch `*/main` + script path `Jenkinsfile` |
| `30`-`34` | GitHub: branches, pull requests, commits on main, Actions runs (green), network graph |

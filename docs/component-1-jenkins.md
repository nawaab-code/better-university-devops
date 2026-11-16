# Component 1: Git + Gradle + Jenkins CI

Everything here ran for real on the VM `hospet` (Ubuntu 25.10, Jenkins 2.580.2 LTS, `http://10.1.1.119:8080/`).
Evidence is in `evidence/component-1/` (see its `README.md` for the file-by-file list).

## 1. Setup
Jenkins (apt package `jenkins`, service `jenkins`, home `/var/lib/jenkins`, port 8080) is configured from the files in
`jenkins/` (reproduction steps in `jenkins/README.md`):

* **Plugins** from `jenkins/plugins.txt` installed with the official *Jenkins Plugin Installation Manager* CLI
  (`jenkins-plugin-manager 2.16.0`), dependencies resolved automatically (148 plugin files).
* **Setup wizard skipped** (`-Djenkins.install.runSetupWizard=false` plus the `lastExecVersion` marker files).
* **Configuration as Code** applied through a systemd drop-in
  (`/etc/systemd/system/jenkins.service.d/override.conf`, `CASC_JENKINS_CONFIG=/var/lib/jenkins/casc`):
  `jenkins.yaml` (security, JDK, root URL) and `jobs.yaml` (the pipeline job through Job DSL).
* **Security**: local `admin` account (approved by the owner) with a random password kept only in
  `/var/lib/jenkins/secrets/bu-admin-password` (mode 600) and read by JCasC with `${readFile:...}`; it is never in git or logs.
  Matrix authorization gives *anonymous* only Overall/Read, Job/Read, Job/ExtendedRead and View/Read, which is why the
  Jenkins pages can be screenshotted without logging in (the *configure* page needs login, so those screenshots were taken as `admin`).
* **JDK split**: Jenkins runs on **JDK 21** (`JAVA_HOME` in the systemd drop-in); builds use **JDK 17**
  (JCasC global environment variable `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64`, also registered as tool `jdk17`),
  because the Gradle build uses `jvmToolchain(17)`. Build #4's console shows `openjdk version "17.0.19"`.
* **Job `bu-campus-api`**: *Pipeline script from SCM*, Git `https://github.com/nawaab-code/better-university-devops.git`,
  branch `*/main`, script path `Jenkinsfile` (screenshots `21`, `24`).

## 2. The pipeline (`Jenkinsfile`)
`Checkout` (explicit `checkout scm`, computes the version) → `Test` (`./gradlew test`, results published with `junit`) →
`Build` (`./gradlew build -x test -PappVersion=<version>`) → on success `archiveArtifacts` selects only `bu-campus-api-${APP_VERSION}-all.jar` and fingerprints it.
The Jenkinsfile needed **no change to run on Linux**; only a `java -version` / `gradlew --version` line was added to the Test stage so the console proves JDK 17 is used.

### Versioning
`version = <BUILD_NUMBER>-<7-char commit sha>`, e.g. `4-8014664`. It becomes the build display name (`#4 v4-8014664`), the
description, and the JAR name `bu-campus-api-4-8014664-all.jar` (Gradle reads `-PappVersion`; the service reports it
through `APP_VERSION`). The version therefore ties every artifact to a build and an exact commit.

### Test stage
Tests run before packaging so a failing test stops publication of a new artifact. 4 JUnit 5 tests
(`CampusApiTest` ×3, `HealthTest` ×1); the JUnit XML is published (*Tests* page, test-result trend on the job page).

## 3. Polling vs webhook
A GitHub webhook makes GitHub call Jenkins the moment a push happens (instant, no wasted requests), but it needs
Jenkins to be reachable from the internet. The VM `10.1.1.119` is on a private campus network and cannot be reached from GitHub,
so the Jenkinsfile uses `pollSCM('* * * * *')`: Jenkins asks GitHub (`git ls-remote`) every minute whether `main` has a new commit and
starts a build when it does. The cost is up to one minute of delay and a request per minute. (Jenkins warns that
`* * * * *` is aggressive; accepted here for a demo, `H/5 * * * *` would be gentler.)
Polling only starts working after the job has run once, because Jenkins registers the trigger from the Jenkinsfile when a build executes,
so **one manual bootstrap build (#1, "Started by user admin") was made**. Every build after that started by itself.

## 4. Proof of automatic CI
| Build | Cause | Commit | Result | Artifact |
|------|-------|--------|--------|----------|
| #1 | manual bootstrap (user admin) | `c7c697a` | SUCCESS | `bu-campus-api-1-c7c697a-all.jar` |
| #2 | **Started by an SCM change** | `45b31c9` merge of PR #8 (Jenkins config files) | SUCCESS | `bu-campus-api-2-45b31c9-all.jar` |
| #3 | Started by an SCM change | `b86e0c9` merge of PR #9 (another worker's Ansible PR) | SUCCESS | `bu-campus-api-3-b86e0c9-all.jar` |
| #4 | **Started by an SCM change** | `8014664` merge of PR #10 (a line added to this document) | SUCCESS | `bu-campus-api-4-8014664-all.jar` |

#2 and #4 are the two required automatic builds; each build page and console shows *Started by an SCM change*, 4 tests passed,
and the versioned JAR archived (`evidence/component-1/screenshots/`). Build #3 was also automatic (see Problems).

## 5. GitHub Actions
`.github/workflows/ci.yml` runs on every push and pull request: JDK 17, Gradle cache, `./gradlew build -PappVersion=<run>-<sha>`
(this includes the tests), then uploads the JAR and the JUnit XML as artifacts. Runs on `main` for PRs #8, #9 and #10 are green
(screenshot `33-github-actions-runs.png`).

## 6. Problems and fixes
* **Jenkins home was not empty.** The apt package had been started once before configuration and had created a setup-wizard
  state (`initialAdminPassword`, an `admin` user, no plugins). Fix: stopped the service, removed that generated state and ran `jenkins/install.sh`.
* **Mac-specific files.** `jenkins.yaml` and `install.sh` used Homebrew paths (`/opt/homebrew/...`) and `~/.jenkins`; rewritten for `/var/lib/jenkins`,
  `/usr/lib/jvm/...` and a systemd drop-in. The permission `Run/Artifacts` in the old matrix does not exist in Jenkins and was removed (anonymous can still view artifacts through Job/Read).
* **Anonymous cannot open the Configure page** (needs Job/Configure). Screenshots of it were taken logged in as `admin`; `config.xml` is also saved (readable anonymously through Job/ExtendedRead).
* **PR-number mix-up.** While merging this branch's second PR, the Ansible worker's PR #9 and mine (#10) were confused, and `gh pr merge 9`
  merged the Ansible PR (its branch CI was green; main CI for the merge was green too). It was reported on PR #9 and in the worker report; it is why build #3 exists.
  Lesson: merge by the number printed by `gh pr create`, not by assumption.
* `curl` with `[...]` in a URL (Jenkins `tree=` queries) needs `-g`; trivial, noted for anyone repeating the checks.

## 7. Second automatic build
This paragraph was pushed to `main` (PR #10) only to give Jenkins a second real change to pick up by polling.

## Reviewer correction
The original wildcard also archived older versioned JARs left in the Jenkins workspace (build #4 contains four JARs). The post action now selects the exact current version. The old screenshots remain historical evidence; the final review captures show the corrected build. PR #8 merged as `754533a` but build #2 checked out `45b31c9`, the branch tip selected during the polling/merge timing. These are different commits.

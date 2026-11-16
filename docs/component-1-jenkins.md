# Component 1: Git + Gradle + Jenkins CI

(Draft written with the setup; evidence section completed at the end.)

## Setup
Jenkins LTS (apt, `jenkins` service, home `/var/lib/jenkins`, port 8080, JDK 21) is configured entirely from
files in `jenkins/` (see `jenkins/README.md`): plugins via the plugin installation manager, Jenkins Configuration
as Code (`CASC_JENKINS_CONFIG` from a systemd drop-in), setup wizard skipped, local admin with a random password
kept only in `/var/lib/jenkins/secrets/`. Builds use JDK 17 (`JAVA_HOME` set by JCasC) because the Gradle build
uses `jvmToolchain(17)`.

## Second automatic build
This paragraph was pushed to `main` (PR #9) only to give Jenkins a second real change to pick up by polling.

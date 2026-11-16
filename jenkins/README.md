# Jenkins on the VM (Ubuntu, apt package)

Files here describe what really runs on the `hospet` VM (`http://10.1.1.119:8080/`).

| File | Purpose |
|------|---------|
| `plugins.txt` | plugins installed with the Jenkins plugin installation manager (dependencies resolved automatically) |
| `jenkins.yaml` | JCasC: local `admin` user, matrix authorization (anonymous = read only), JDK 17 for builds, root URL |
| `jobs.yaml` | JCasC + Job DSL: pipeline job `bu-campus-api` (Pipeline script from SCM, `*/main`, `Jenkinsfile`) |
| `install.sh` | does everything below in one go |

## Reproduce

```bash
sudo apt-get install -y openjdk-17-jdk openjdk-21-jdk   # 21 runs Jenkins, 17 runs the builds
# add the Jenkins LTS apt repo (https://pkg.jenkins.io/debian-stable), then:
jenkins/install.sh
```

`install.sh`: installs the `jenkins` package, downloads `jenkins-plugin-manager`, generates a random admin
password in `/var/lib/jenkins/secrets/bu-admin-password` (mode 600, never committed), installs the plugins,
copies the JCasC files to `/var/lib/jenkins/casc/`, skips the setup wizard, writes the systemd drop-in
`/etc/systemd/system/jenkins.service.d/override.conf` (`CASC_JENKINS_CONFIG`, `-Djenkins.install.runSetupWizard=false`,
`JAVA_HOME` = JDK 21) and enables the service.

JDK split: Jenkins itself runs on JDK 21 (systemd `JAVA_HOME`); builds get `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64`
from a JCasC global environment variable (also registered as the tool `jdk17`), matching `jvmToolchain(17)`.

Anonymous users can read jobs, builds and artifacts (so pages can be screenshotted); only `admin` can configure or trigger.
The Jenkins admin password is read with `sudo cat /var/lib/jenkins/secrets/bu-admin-password`.

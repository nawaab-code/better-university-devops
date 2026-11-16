#!/bin/bash
# Local setup of Jenkins for this project (macOS + Homebrew `jenkins-lts`).
#   PLUGIN_MANAGER_JAR=/path/to/jenkins-plugin-manager.jar jenkins/install.sh [with-job]
# Brew's service listens on 127.0.0.1:8080 only. Without "with-job" only the controller,
# security and plugins are set up; "with-job" also adds the bu-campus-api pipeline job.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
JENKINS_HOME="${JENKINS_HOME:-$HOME/.jenkins}"
PLUGIN_MANAGER_JAR="${PLUGIN_MANAGER_JAR:?path to jenkins-plugin-manager-*.jar}"
WAR=/opt/homebrew/opt/jenkins-lts/libexec/jenkins.war

mkdir -p "$JENKINS_HOME/casc" "$JENKINS_HOME/plugins"

# 1. admin password: generated once, stored only in the Jenkins home (mode 600)
if [ ! -f "$JENKINS_HOME/bu-admin-password" ]; then
  (umask 077; openssl rand -base64 24 | tr -d '/+=\n' > "$JENKINS_HOME/bu-admin-password")
fi

# 2. plugins, resolved against the installed jenkins.war
/opt/homebrew/opt/openjdk@21/bin/java -jar "$PLUGIN_MANAGER_JAR" \
  --war "$WAR" --plugin-file "$HERE/plugins.txt" \
  --plugin-download-directory "$JENKINS_HOME/plugins"

# 3. configuration as code (the casc folder is read through CASC's default $JENKINS_HOME/jenkins.yaml
#    and the extra folder below; both are the same files)
sed "s#__JENKINS_HOME__#$JENKINS_HOME#g" "$HERE/jenkins.yaml" > "$JENKINS_HOME/jenkins.yaml"
if [ "${1:-}" = "with-job" ]; then
  cp "$HERE/jobs.yaml" "$JENKINS_HOME/casc/jobs.yaml"
fi

# 4. skip the setup wizard: tell Jenkins this home already ran this version
printf '%s' "2.580.2" > "$JENKINS_HOME/jenkins.install.InstallUtil.lastExecVersion"
printf '%s' "2.580.2" > "$JENKINS_HOME/jenkins.install.UpgradeWizard.state"

echo "Done. Start with: brew services start jenkins-lts"

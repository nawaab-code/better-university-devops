#!/bin/bash
# Setup of the apt-installed Jenkins LTS on Ubuntu (the hospet VM). Run as a user with sudo:
#   jenkins/install.sh
# Result: plugins from plugins.txt, JCasC (security + JDK 17 + the bu-campus-api job),
# random admin password in /var/lib/jenkins/secrets, setup wizard skipped, service on :8080.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
JH=/var/lib/jenkins
PMV=2.16.0
PM=/opt/jenkins-tools/jenkins-plugin-manager-$PMV.jar
WAR=/usr/share/java/jenkins.war

sudo apt-get install -y jenkins >/dev/null          # package: /usr/share/java/jenkins.war, user jenkins
sudo systemctl stop jenkins || true

# 1. plugin installation manager (official CLI)
sudo mkdir -p /opt/jenkins-tools
[ -f "$PM" ] || sudo curl -fsSL -o "$PM" \
  https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/$PMV/jenkins-plugin-manager-$PMV.jar

# 2. admin password: generated once, only inside the Jenkins home (mode 600, never committed)
sudo mkdir -p $JH/secrets $JH/casc
if [ ! -f $JH/secrets/bu-admin-password ]; then
  openssl rand -base64 24 | tr -d '/+=\n' | sudo tee $JH/secrets/bu-admin-password >/dev/null
  sudo chmod 600 $JH/secrets/bu-admin-password
fi

# 3. plugins, resolved against the installed war
sudo mkdir -p $JH/plugins
sudo java -jar "$PM" --war "$WAR" --plugin-file "$HERE/plugins.txt" --plugin-download-directory $JH/plugins

# 4. configuration as code
sed "s#__JENKINS_HOME__/bu-admin-password#$JH/secrets/bu-admin-password#g" "$HERE/jenkins.yaml" | sudo tee $JH/casc/jenkins.yaml >/dev/null
sudo cp "$HERE/jobs.yaml" $JH/casc/jobs.yaml

# 5. skip the setup wizard
VER=$(unzip -p $WAR META-INF/MANIFEST.MF | tr -d '\r' | awk -F': ' '/^Jenkins-Version/{print $2}')
printf '%s' "$VER" | sudo tee $JH/jenkins.install.InstallUtil.lastExecVersion >/dev/null
printf '%s' "$VER" | sudo tee $JH/jenkins.install.UpgradeWizard.state >/dev/null

# 6. systemd drop-in: JCasC location, no wizard, JDK 21 for Jenkins itself, allow the Job DSL script
sudo mkdir -p /etc/systemd/system/jenkins.service.d
sudo tee /etc/systemd/system/jenkins.service.d/override.conf >/dev/null <<EOF
[Service]
Environment="CASC_JENKINS_CONFIG=$JH/casc"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
Environment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
EOF
sudo chown -R jenkins:jenkins $JH
sudo systemctl daemon-reload
sudo systemctl enable --now jenkins
echo "Jenkins starting on :8080 (admin password in $JH/secrets/bu-admin-password)"

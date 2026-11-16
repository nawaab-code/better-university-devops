# Final reviewer evidence

Real captures on hospet, 2026-11-16. Terminal captures have raw `.log` and freeze `.png` pairs, date/hostname headers, Dracula theme, window frame, padding 20 and font size 14. Browser screenshots are Playwright/Chromium at a 1440-pixel-wide viewport. Browser zoom in 27–31 changes presentation only; no screenshot pixels or results were edited.

Selections from saved worker logs are explicitly labelled by the command and original filename; they are not new playbook/rollback executions. Full original logs remain in their component evidence directories. The live reviewer repeated scaling and verified restoration with a matching kubectl client. JSON in 25 is the selected live probe fields, not a hand-written manifest.

| File | What it proves / limitation |
| --- | --- |
| `01-versions.log` | Live tool and OS versions; original kubectl client was 1.37.2. |
| `01-versions.png` | Live tool and OS versions; original kubectl client was 1.37.2. |
| `02-git-review.log` | Merged PRs, closed worker issues and Git merge history. |
| `02-git-review.png` | Merged PRs, closed worker issues and Git merge history. |
| `03-ansible-recaps.log` | Search of original Ansible recaps (long source paths). |
| `03-ansible-recaps.png` | Search of original Ansible recaps (long source paths). |
| `04-scale-evidence.log` | Search of original scaling logs (long source paths). |
| `04-scale-evidence.png` | Search of original scaling logs (long source paths). |
| `05-rollback-evidence.log` | Search of original broken rollout and undo logs. |
| `05-rollback-evidence.png` | Search of original broken rollout and undo logs. |
| `06-live-state.log` | Initial reviewer live cluster and service checks; very wide command line, superseded for print by 24. |
| `06-live-state.png` | Initial reviewer live cluster and service checks; very wide command line, superseded for print by 24. |
| `07-build-evidence.log` | Original build-4 console tail and successful main Actions runs. |
| `07-build-evidence.png` | Original build-4 console tail and successful main Actions runs. |
| `08-configmap-evidence.log` | Original ConfigMap log search with version observations. |
| `08-configmap-evidence.png` | Original ConfigMap log search with version observations. |
| `09-docker-evidence.log` | Saved Docker image/runtime inspection output. |
| `09-docker-evidence.png` | Saved Docker image/runtime inspection output. |
| `10-archived-jars.png` | Playwright artifact directory for build 4: four JARs reveal stale workspace archival. |
| `11-ansible-runs.log` | Literal PLAY RECAP selections from all four original Ansible runs. |
| `11-ansible-runs.png` | Literal PLAY RECAP selections from all four original Ansible runs. |
| `12-scaling.log` | Literal selections of original three/five/three deployment and pod tables. |
| `12-scaling.png` | Literal selections of original three/five/three deployment and pod tables. |
| `13-broken-rollout.log` | Literal selections of original broken rollout, HTTP checks and timeout. |
| `13-broken-rollout.png` | Literal selections of original broken rollout, HTTP checks and timeout. |
| `14-rollback.log` | Literal selections of original rollback; image 1.0.0 but ConfigMap still 1.0.1-configmap. |
| `14-rollback.png` | Literal selections of original rollback; image 1.0.0 but ConfigMap still 1.0.1-configmap. |
| `15-configmap.log` | Literal selections of original ConfigMap change/restart/health evidence. |
| `15-configmap.png` | Literal selections of original ConfigMap change/restart/health evidence. |
| `16-docker-build.log` | Original Docker export success and image content size comparison. |
| `16-docker-build.png` | Original Docker export success and image content size comparison. |
| `17-git-merges.log` | Reviewer Git merges and feature branches including PR 13. |
| `17-git-merges.png` | Reviewer Git merges and feature branches including PR 13. |
| `18-client-check.log` | Checksum-installed matching kubectl 1.33.1 reads the Kubernetes 1.33.1 node. |
| `18-client-check.png` | Checksum-installed matching kubectl 1.33.1 reads the Kubernetes 1.33.1 node. |
| `19-test-build.log` | Tail of reviewer JDK17 Gradle build, successful with all tasks executed. |
| `19-test-build.png` | Tail of reviewer JDK17 Gradle build, successful with all tasks executed. |
| `20-live-scale.log` | Reviewer live scale from 3 to 5 to 3; last table includes two terminating Pods, not five active replicas. |
| `20-live-scale.png` | Reviewer live scale from 3 to 5 to 3; last table includes two terminating Pods, not five active replicas. |
| `21-corrected-archive.log` | Build 6 API/console/JUnit checks; long checkout line makes this unsuitable for print, superseded by 26. |
| `21-corrected-archive.png` | Build 6 API/console/JUnit checks; long checkout line makes this unsuitable for print, superseded by 26. |
| `22-restored-state.log` | Three running Pods after scale-down termination completed; health 1.0.0. |
| `22-restored-state.png` | Three running Pods after scale-down termination completed; health 1.0.0. |
| `23-current-artifact.png` | Playwright build-6 artifact directory at normal zoom, exactly one current JAR. |
| `24-live-services.log` | Live Deployment/Pods/Service and health of both Kubernetes and Ansible services. |
| `24-live-services.png` | Live Deployment/Pods/Service and health of both Kubernetes and Ansible services. |
| `25-health-probes.log` | Selected probe fields from the live Deployment API response, JSON pretty printed. |
| `25-health-probes.png` | Selected probe fields from the live Deployment API response, JSON pretty printed. |
| `26-compact-ci.log` | Compact build-6 console cause/status and API archive/test summaries. |
| `26-compact-ci.png` | Compact build-6 console cause/status and API archive/test summaries. |
| `27-current-artifact-zoom.png` | Playwright build-6 artifact directory at 160% browser zoom for print. |
| `28-poll-scm-readable.png` | Authenticated Jenkins configuration: Poll SCM and actual schedule, 160% browser zoom. |
| `29-scm-readable.png` | Authenticated Jenkins configuration: Pipeline from SCM / Git / repository field, 160% browser zoom. The long input value is horizontally clipped; full URL is in raw job XML and the original component-1 capture 22. |
| `30-script-readable.png` | Authenticated Jenkins configuration: script path Jenkinsfile, 160% browser zoom. Does not prove the branch field above the viewport. |
| `31-tests-readable.png` | Authenticated Jenkins build-6 JUnit UI, four passing tests, 160% browser zoom. |

The filled report, PDF page renders and compile logs are intentionally local in the ignored `assignment/report/` directory. The final PDF does not use every capture here; unused/wide captures remain available for audit.

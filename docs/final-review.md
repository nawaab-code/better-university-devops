# Final assignment review

The three worker reports were present and their processes had finished. PRs #8–#12 were merged; issues #2–#4 were closed. The review compared the course brief with the source files, raw logs and selected screenshots.

The Git, Gradle, Jenkins, Ansible, Docker and Kubernetes requirements have real evidence. Jenkins builds #2 and #4 show SCM causes; four JUnit tests pass; Actions runs are successful. Ansible records first deployment, unchanged rerun, upgrade and unchanged rerun. The cluster logs show matching labels/selectors, 3→5→3 scaling, a NodePort response, ConfigMap restart semantics, failed probes and explicit rollback.

## Corrections

- Jenkins previously archived `build/libs/*-all.jar`, including old workspace JARs. PR #13 (`12d4c3f`) changed it to the exact current version. SCM-triggered build #6 passed four tests and archived only `bu-campus-api-6-12d4c3f-all.jar` (review evidence 26–27).
- Docker is 29.1.3; kind is 0.29.0; the Kubernetes node is 1.33.1. These are distinct versions. Worker kubectl was 1.37.2. A checksum-verified kubectl 1.33.1 binary in `~/devops-tools` was used for final checks and a second scaling run.
- Image rollback restored image 1.0.0 while `/health` still reported ConfigMap value 1.0.1-configmap. ConfigMap restoration was a separate final operation; reviewer health confirms 1.0.0.
- Component-1 screenshots 14 and 16 are identical login redirects, despite their filenames. Their README entries now say so. They are not used in the report. Captures 08/09 show an artifact folder rather than the actual filenames; review captures open that folder.
- The Jenkins worker handoff misidentified PR #11's merge as `10f841e`; GitHub and Git history show `be12e0c`. `10f841e` is PR #12. PR #8 merged as `754533a`, while Jenkins build #2 checked out `45b31c9`. The report distinguishes these.
- Fixed the stale Mac comment in the kind host-port mapping and the root README claim that Gradle automatically downloads a missing JDK. Added reproduction links and `repo_link.txt`.

## Validation and interpretation

The reviewer JDK 17 Gradle build passed all four tests and packaged the JAR. Jenkins #6 exercised the corrected pipeline after merging PR #13. The live reviewer scaling run returned to three ready Pods; both Kubernetes (1.0.0) and Ansible (1.1.0) health responses are recorded. All report figures were opened and compared with the claims and logs. Selected UI captures were repeated at 160% browser zoom for print.

The pipeline is an automated CI build followed by explicit deployment exercises, not automatic continuous deployment. Ansible uses SSH to the same VM as its controller. Kubernetes is single-node kind with locally loaded images and per-Pod in-memory data; no HPA, registry, persistent/shared data store or Prometheus server is claimed. Rollback was an explicit undo after probes blocked the update.

The filled LaTeX report and PDF remain ignored under `assignment/report/`, as required for student identification. They preserve the fixed banner, certificate wording, component list, rubric and blank marks table. Small title-page spacing adjustments keep the added project title and student name on one page. The template's banner uses minipages totalling 104% of text width and emits two inherited hbox warnings; it is preserved exactly and is visibly unclipped. No listing overflow remains.

Final PDF validation: 44 pages rendered at 60 dpi and inspected page by page; 18 copied figures match their evidence originals byte for byte. Sixteen complete source listings and the labelled Ansible tasks excerpt match the repository. Placeholder and instruction-box searches pass. The PDF remains local and excluded from the PR. The brief's course-coordinator collaborator step could not be completed because no GitHub identity was supplied.

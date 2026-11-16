# Better University Campus API — DevOps pipeline

A small Kotlin REST service from the Better University project, used to show a
full DevOps pipeline: Git → Gradle → Jenkins → Ansible → Docker → Kubernetes.

Better University is MSRIT's academic and student-social app (iOS, Android, a
Next.js API on Cloud Run). Its production code lives in a private repository
and is not changed by this work. This repository holds a self-contained slice
of its campus data API, with in-memory sample data only (no student records),
so the pipeline can be shown end to end without touching production.

## Build and run

Install JDK 17 before building (the build selects its Java 17 toolchain).

```bash
./gradlew build                      # compile, run tests, package the JAR
PORT=8090 java -jar build/libs/bu-campus-api-1.0.0-SNAPSHOT-all.jar
curl http://localhost:8090/health
```

The port comes from the `PORT` environment variable (default 8080).

## Endpoints

| Method | Path | What it does |
| --- | --- | --- |
| GET | `/health` | `{"status":"UP", ...}` with the running version |
| GET | `/api/v1/announcements?department=CY` | Lists campus announcements (optional department filter) |
| POST | `/api/v1/announcements` | Adds an announcement; `201`, or `400` when the title is blank |
| GET | `/api/v1/timetable/{section}` | Sample timetable for a section such as `CY-5A`; `404` if unknown |

Data is held in memory and reset on restart. Every running copy has its own
list, so with several replicas a new announcement shows only on the copy that
received it.

## Evidence

Captured command output and screenshots live in [`evidence/`](evidence/),
one folder per assignment component.

## Pipeline at a glance

Code → Gradle → Jenkins → Ansible → Docker → Kubernetes.
Jenkins automatically polls Git, tests and packages a versioned JAR. Ansible
and Docker/Kubernetes demonstrate two explicit deployment paths for that same
service; Jenkins does not automatically invoke either deployment.

## Reproduce the assignment

- [Component 1: Git, Gradle and Jenkins](docs/component-1-jenkins.md): install JDK 17, run `./gradlew build`, then follow [Jenkins setup](jenkins/README.md). Push a merged change and wait for SCM polling. [CI evidence](evidence/component-1/).
- [Component 2: Ansible](docs/component-2-ansible.md): generate the local SSH key described there, build version 1.0.0, then run `ansible-playbook -i inventory.ini playbook.yml` from `ansible/`. Repeat unchanged to check idempotence. The target is this VM over SSH and the app uses 8081. [Ansible evidence](evidence/component-2/ansible/).
- [Component 2: Docker and Kubernetes](docs/component-2-kubernetes.md): build the image, create kind, load the image, apply manifests, scale and verify:

```bash
docker build --build-arg APP_VERSION=1.0.0 -t bu-campus-api:1.0.0 .
kind create cluster --name bu-campus --config k8s/kind-cluster.yaml
kind load docker-image bu-campus-api:1.0.0 --name bu-campus
kubectl apply -f k8s/configmap.yaml -f k8s/deployment.yaml -f k8s/service.yaml
kubectl rollout status deployment/bu-campus-api
kubectl get pods
kubectl scale deployment bu-campus-api --replicas=5
kubectl rollout status deployment/bu-campus-api
kubectl get pods
kubectl scale deployment bu-campus-api --replicas=3
curl http://localhost:30080/health
```

Use an existing `bu-campus` cluster if already created. The kind configuration
is a cluster-creation file, not a manifest for `kubectl apply`.
[Docker evidence](evidence/component-2/docker/) ·
[Kubernetes evidence](evidence/component-2/kubernetes/) ·
[Final review evidence](evidence/review/).

The filled course PDF is intentionally excluded from Git because it contains
student identification. The source template is in `assignment/`.

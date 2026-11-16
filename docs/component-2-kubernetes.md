# Component 2 (part 2): Docker image and Kubernetes deployment

Evidence: `evidence/component-2/docker/` and `evidence/component-2/kubernetes/`. Everything below was run on VM `hospet` (Docker 29.1.3, kind v0.29.0 / Kubernetes v1.33.1 single node `bu-campus`).

## 1. Docker: multi-stage image

`Dockerfile` has two stages. Stage 1 (`gradle:8.13-jdk17`) copies the Gradle files first (so the dependency layer is cached) then the sources and runs `./gradlew build -x test -PappVersion=$APP_VERSION` (tests are run in Jenkins, not repeated here). Stage 2 (`eclipse-temurin:17-jre-alpine`) copies only the fat JAR, creates a non-root user `bu`, sets `ENV PORT=8080 APP_VERSION=...`, `EXPOSE 8080`.

Result: the runtime image is **82 MB** (content size) against **761 MB** for the build stage; `docker exec ... which gradle javac` finds nothing and the process runs as `uid=100(bu)`. Smaller image = faster `kind load`/pulls, smaller attack surface, no build tools or sources in production.

## 2. Kubernetes objects

* **Pod**: smallest unit, one running copy of the container; it is disposable and has its own IP.
* **ReplicaSet**: keeps N identical Pods alive (replaces any that die). Owned by a Deployment; pods names are `<deployment>-<rs-hash>-<random>`.
* **Deployment**: the thing we write. Manages ReplicaSets: one per pod-template version. Scaling changes the RS replica count; an update creates a *new* RS and moves pods gradually (`RollingUpdate`, `maxSurge 1`, `maxUnavailable 0`); old RSs are kept at 0 replicas as revision history, which is what makes rollback possible.

**Labels and selectors.** Pods carry `app=bu-campus-api, tier=backend`. The Deployment selector and the Service selector both use those labels, so "which pods belong to me" is decided purely by labels (`kubectl get pods -l app=bu-campus-api` shows the same set; `-l tier=frontend` matches nothing). The ReplicaSet adds `pod-template-hash` so versions don't overlap. See `05-label-selectors`.

**Service (NodePort 30080).** Gives a stable virtual IP/port in front of changing pod IPs and only routes to *Ready* pods (the Endpoints list). kind's `extraPortMappings` maps node port 30080 to host 127.0.0.1:30080, so `curl localhost:30080` works.

**Probes** (both `GET /health`):
* *Readiness*: "may this pod receive traffic?" Failing = removed from Service endpoints, rollout does not progress. Starts after 5 s, every 5 s.
* *Liveness*: "is the process stuck?" Failing 3 times = kubelet restarts the container. Starts after 15 s, every 10 s.
In the rollback demo both fired against the broken image (events in `12-rollout-broken`).

**ConfigMap.** `bu-campus-api-config` holds `PORT` and `APP_VERSION`, injected via `envFrom`. This separates config from the image (same image in dev/prod). Observed behaviour: patching the ConfigMap does **not** change running pods (env vars are read at container start); `kubectl rollout restart` created a new ReplicaSet and `/health` then reported `1.0.1-configmap` (`10-configmap-change`). I restored the committed value afterwards.

**Scaling.** `kubectl scale --replicas=5` created two pods that were Ready about 8 s later (JVM start + readiness delay); scaling to 3 terminated two. Same ReplicaSet throughout (`DESIRED` 3→5→3). Observation: terminating pods showed `Error` status because the JVM exits with code 143 on SIGTERM; harmless here.

**Rollback.** The broken image `bu-campus-api:2.0.0-broken` was built from a throwaway Dockerfile in `/tmp` (copy in the evidence folder; **no broken code was committed**): `FROM bu-campus-api:1.0.0` with an overridden `ENTRYPOINT` that sleeps instead of starting the server, so nothing listens on 8080. `kubectl set image` created a new ReplicaSet; its pod never became Ready (readiness refused, then liveness kill), and because `maxUnavailable: 0` the 3 old pods stayed up: 30 consecutive `/health` calls all returned 200. `kubectl rollout undo` re-activated the previous ReplicaSet (revision 2 became revision 4), the broken pod was terminated, and 3/3 were Ready again on image 1.0.0. At this point `/health` still reported `1.0.1-configmap`; the ConfigMap was restored separately in `14-final-state`.

## 3. Prometheus and `/health`

Prometheus scrapes HTTP endpoints that return text in its exposition format. Today `/health` returns JSON `{"status":"UP",...}`: Prometheus could probe it with the blackbox exporter (up/down, latency, HTTP status), and `probe_success` records whether the HTTP probe succeeds. The Prometheus `up` metric records whether the exporter scrape succeeds. A `/metrics` endpoint (e.g. Micrometer `PrometheusMeterRegistry` in Ktor) would add request count and latency histograms per route/status, JVM heap/GC/threads, and custom counters such as announcements created, enabling alerts like error rate > 5% or p95 latency.

## 4. Problems and fixes

| Problem | Fix |
|---|---|
| Draft files had never run | Reviewed; they worked unchanged (image built first time, manifests applied cleanly). |
| First `kubectl get nodes` right after `kind create` showed `NotReady` | Normal 10-20 s CNI start; waited and recaptured (`02-nodes-ready`). |
| `describe pod` capture used wrong syntax (`pod pod/name`) | Re-ran as `04b-describe-pod-probes`. |
| POST with field `audience` gave 400 | The API field is `department`; both attempts kept in the logs. |
| Data differs between GETs through the Service | In-memory store is per pod: a stateless-service limitation, would need a shared database (`07-post-statefulness`). |
| 26 MB PNG of the full build log | Condensed render for the PNG, full text in the `.log`. |

## 5. Limitations
Single-node kind on a VM; image delivered with `kind load`, no registry; `kubectl rollout undo` does not update the `last-applied-configuration` annotation (kubectl warns about this).

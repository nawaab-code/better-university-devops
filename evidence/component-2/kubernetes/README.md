# Component 2 – Kubernetes evidence (DEVOPS-03)

Single-node kind cluster `bu-campus` on VM `hospet`. Every `.png` is a `freeze` render of the same-named `.log`; each log starts with `date` + `hostname`.

| File | Proves |
|---|---|
| `01-cluster-create` | `kind create cluster --config k8s/kind-cluster.yaml`, `kind load docker-image`, first `get nodes` (still NotReady 9 s after create, real). |
| `02-nodes-ready` | Node Ready; image present inside the node (`crictl images`). |
| `03-apply-rollout` | apply ConfigMap → Deployment → Service, `rollout status`, `get pods -o wide --show-labels`, `get deploy,rs,svc,ep` (3 endpoints). |
| `04-describe-deployment` | `describe deployment`: selector, RollingUpdate 0 unavailable/1 surge, probes, env from ConfigMap, limits; ConfigMap YAML. |
| `04b-describe-pod-probes` | Pod Ready conditions (Initialized/Ready/ContainersReady/PodScheduled) + probes. |
| `05-label-selectors` | `-l app=bu-campus-api`, multi-label selector, non-matching selector, Service selector. |
| `06-service-curl` | `/health`, announcements, timetable via `http://localhost:30080`; each pod IP answers; 12×200 through the Service. (Contains one real 400 from a POST with a wrong field name.) |
| `07-post-statefulness` | POST succeeds (201) after fixing the field name; repeated GETs show the in-memory store is per pod (id 3 appears only on one pod). |
| `08-scale-up-5` | `scale --replicas=5`: timestamped `get pods -w` (Pending → ContainerCreating → Running → 1/1 after ~8 s), 5/5, RS before/after. |
| `09-scale-down-3` | scale back to 3: Terminating pods, 3 Running, ScalingReplicaSet events. |
| `10-configmap-change` | Patch ConfigMap APP_VERSION=1.0.1-configmap; /health unchanged until `rollout restart`; then reports new value; history. |
| `11-broken-image-build` + `11-broken-image(.Dockerfile/-Dockerfile.png)` | The throwaway `/tmp` Dockerfile (never committed to the app) and the build/`kind load` of `bu-campus-api:2.0.0-broken`. |
| `12-rollout-broken` | `set image` to the broken tag: new pod stays 0/1 (readiness + liveness failures in events), the 3 old pods keep serving, 30× curl all 200, `rollout status` times out, history rev 3. |
| `13-rollback-undo` | `rollout undo`: old ReplicaSet scaled back, broken pod Terminating, 3/3, image 1.0.0, 200s, history 1,3,4. |
| `14-final-state` | ConfigMap restored to 1.0.0 + restart; final 3/3 on 1.0.0; node port mapping. |
| `yaml-*.png` | Renders of `k8s/configmap.yaml`, `deployment.yaml`, `service.yaml`, `kind-cluster.yaml`. |

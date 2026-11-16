# Better University Campus API — DevOps pipeline

A small Kotlin REST service from the Better University project, used to show a
full DevOps pipeline: Git → Gradle → Jenkins → Ansible → Docker → Kubernetes.

Better University is MSRIT's academic and student-social app (iOS, Android, a
Next.js API on Cloud Run). Its production code lives in a private repository
and is not changed by this work. This repository holds a self-contained slice
of its campus data API, with in-memory sample data only (no student records),
so the pipeline can be shown end to end without touching production.

## Build and run

Needs JDK 17 (Gradle downloads it if missing).

```bash
./gradlew build                      # compile, run tests, package the JAR
java -jar build/libs/bu-campus-api-1.0.0-SNAPSHOT-all.jar
curl http://localhost:8080/health
```

The port comes from the `PORT` environment variable (default 8080).

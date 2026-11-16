# Component 2 – Docker evidence (DEVOPS-03)

All captures were run on VM `hospet` (each log starts with `date` + `hostname`). Every `.png` is a `freeze` render of the `.log` of the same name.

| File | Proves |
|---|---|
| `01-docker-build.log/.png` | Multi-stage `docker build -t bu-campus-api:1.0.0` succeeded (Gradle runs `./gradlew build -x test -PappVersion=1.0.0` in stage 1). PNG is a condensed view (head + step list); the `.log` is the full output. |
| `02-docker-run-health.log/.png` | `docker run -p 18090:8080`, `/health` returns 200 `{"status":"UP",...,"version":"1.0.0"}`, timetable works, the process runs as non-root `uid=100(bu)`, and `gradle`/`javac` are absent from the runtime image. |
| `03-docker-images-history.log/.png` | Final image content size 82 MB vs 761 MB for the build stage (`bu-campus-api:build-stage`, built with `--target build` only for this comparison); `docker history` shows only JRE + one 15 MB jar layer; `User=bu`, `PORT/APP_VERSION` env, exposed 8080. |
| `04-Dockerfile.png` | Render of the committed `Dockerfile`. |

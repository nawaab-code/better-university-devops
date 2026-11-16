# syntax=docker/dockerfile:1

# ---- Stage 1: build the fat JAR (Gradle + JDK 17 live only in this stage) ----
FROM gradle:8.13-jdk17 AS build
ARG APP_VERSION=1.0.0
WORKDIR /workspace

# Copy the build definition first so the dependency download is cached
# until build.gradle.kts or the wrapper changes.
COPY gradlew settings.gradle.kts build.gradle.kts ./
COPY gradle ./gradle
RUN ./gradlew --no-daemon dependencies > /dev/null 2>&1 || true

COPY src ./src
RUN ./gradlew --no-daemon build -x test -PappVersion=${APP_VERSION}

# ---- Stage 2: runtime image (JRE only, no Gradle, no sources) ----
FROM eclipse-temurin:17-jre-alpine
ARG APP_VERSION=1.0.0

# Run as an unprivileged user instead of root.
RUN addgroup -S bu && adduser -S -G bu bu
WORKDIR /app
COPY --from=build /workspace/build/libs/bu-campus-api-${APP_VERSION}-all.jar /app/app.jar
USER bu

# PORT and APP_VERSION are overridden by the Kubernetes ConfigMap.
ENV PORT=8080 \
    APP_VERSION=${APP_VERSION}
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

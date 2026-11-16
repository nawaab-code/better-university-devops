plugins {
    kotlin("jvm") version "2.1.21"
    kotlin("plugin.serialization") version "2.1.21"
    id("io.ktor.plugin") version "3.1.3"
}

group = "com.nawaablabs.bu"
// CI passes -PappVersion=<build>-<sha>; a local build stays a snapshot.
version = (findProperty("appVersion") as String?) ?: "1.0.0-SNAPSHOT"

application {
    mainClass.set("com.nawaablabs.bu.campus.ApplicationKt")
}

kotlin {
    jvmToolchain(17)
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("io.ktor:ktor-server-core")
    implementation("io.ktor:ktor-server-netty")
    implementation("io.ktor:ktor-server-content-negotiation")
    implementation("io.ktor:ktor-server-status-pages")
    implementation("io.ktor:ktor-serialization-kotlinx-json")
    implementation("ch.qos.logback:logback-classic:1.5.18")

    testImplementation("io.ktor:ktor-server-test-host")
    testImplementation(kotlin("test-junit5"))
}

tasks.test {
    useJUnitPlatform()
    testLogging {
        events("passed", "failed", "skipped")
    }
}

// The runnable artifact: one JAR with every dependency inside.
ktor {
    fatJar {
        archiveFileName.set("bu-campus-api-${project.version}-all.jar")
    }
}

tasks.build {
    dependsOn("buildFatJar")
}

// Only the runnable JAR is shipped; skip the zip/tar distributions.
listOf("distZip", "distTar", "shadowDistZip", "shadowDistTar", "startShadowScripts").forEach { name ->
    tasks.named(name) { enabled = false }
}

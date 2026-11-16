package com.nawaablabs.bu.campus

import io.ktor.http.HttpStatusCode
import io.ktor.serialization.kotlinx.json.json
import io.ktor.server.application.Application
import io.ktor.server.application.install
import io.ktor.server.engine.embeddedServer
import io.ktor.server.netty.Netty
import io.ktor.server.plugins.contentnegotiation.ContentNegotiation
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.routing
import kotlinx.serialization.Serializable

@Serializable
data class Health(val status: String, val service: String, val version: String)

@Serializable
data class ApiError(val error: String)

fun main() {
    // The port comes from the environment so Ansible, Docker and Kubernetes can each set it.
    val port = System.getenv("PORT")?.toIntOrNull() ?: 8080
    embeddedServer(Netty, port = port, host = "0.0.0.0", module = Application::module).start(wait = true)
}

fun Application.module(store: CampusStore = CampusStore()) {
    install(ContentNegotiation) { json() }
    routing {
        get("/health") {
            call.respond(Health(status = "UP", service = "bu-campus-api", version = appVersion()))
        }

        // GET /api/v1/announcements?department=CY
        get("/api/v1/announcements") {
            call.respond(store.list(call.request.queryParameters["department"]?.uppercase()))
        }

        post("/api/v1/announcements") {
            val input = call.receive<NewAnnouncement>()
            if (input.title.isBlank()) {
                call.respond(HttpStatusCode.BadRequest, ApiError("title is required"))
                return@post
            }
            call.respond(HttpStatusCode.Created, store.add(input))
        }

        // GET /api/v1/timetable/CY-5A
        get("/api/v1/timetable/{section}") {
            val section = call.parameters["section"].orEmpty()
            val slots = store.timetable(section)
            if (slots == null) {
                call.respond(HttpStatusCode.NotFound, ApiError("no timetable for section $section"))
            } else {
                call.respond(slots)
            }
        }
    }
}

fun appVersion(): String = System.getenv("APP_VERSION") ?: "dev"

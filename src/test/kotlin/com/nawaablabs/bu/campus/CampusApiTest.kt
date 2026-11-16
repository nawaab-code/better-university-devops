package com.nawaablabs.bu.campus

import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import io.ktor.server.testing.testApplication
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class CampusApiTest {
    @Test
    fun listsSeededAnnouncements() = testApplication {
        application { module(CampusStore()) }
        val response = client.get("/api/v1/announcements")
        assertEquals(HttpStatusCode.OK, response.status)
        assertTrue(response.bodyAsText().contains("Semester timetable published"))
    }

    @Test
    fun createsAnnouncementAndRejectsBlankTitle() = testApplication {
        application { module(CampusStore()) }
        val created = client.post("/api/v1/announcements") {
            contentType(ContentType.Application.Json)
            setBody("""{"title":"Fest on Friday","body":"Main ground, 5 PM","department":"all"}""")
        }
        assertEquals(HttpStatusCode.Created, created.status)
        assertTrue(created.bodyAsText().contains("\"id\":3"))

        val blank = client.post("/api/v1/announcements") {
            contentType(ContentType.Application.Json)
            setBody("""{"title":"  "}""")
        }
        assertEquals(HttpStatusCode.BadRequest, blank.status)
    }

    @Test
    fun returnsTimetableForKnownSectionOnly() = testApplication {
        application { module(CampusStore()) }
        val known = client.get("/api/v1/timetable/cy-5a")
        assertEquals(HttpStatusCode.OK, known.status)
        assertTrue(known.bodyAsText().contains("DevOps"))
        assertEquals(HttpStatusCode.NotFound, client.get("/api/v1/timetable/XX-9Z").status)
    }
}

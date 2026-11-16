package com.nawaablabs.bu.campus

import kotlinx.serialization.Serializable
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicInteger

@Serializable
data class Announcement(val id: Int, val title: String, val body: String, val department: String)

@Serializable
data class NewAnnouncement(val title: String = "", val body: String = "", val department: String = "ALL")

@Serializable
data class TimetableSlot(val day: String, val start: String, val end: String, val course: String, val room: String)

/**
 * In-memory store with sample data only. Each running copy of the service keeps
 * its own list, which is fine for a pipeline demo and loses nothing real.
 */
class CampusStore {
    private val nextId = AtomicInteger(1)
    private val announcements = CopyOnWriteArrayList<Announcement>()

    init {
        add(NewAnnouncement("Semester timetable published", "The odd-semester timetable is now in the app.", "ALL"))
        add(NewAnnouncement("DevOps lab moved", "Thursday's DevOps lab is in LHC-104.", "CY"))
    }

    fun list(department: String?): List<Announcement> =
        if (department == null) announcements.toList()
        else announcements.filter { it.department == department || it.department == "ALL" }

    fun add(input: NewAnnouncement): Announcement {
        val item = Announcement(nextId.getAndIncrement(), input.title.trim(), input.body.trim(), input.department.uppercase())
        announcements.add(item)
        return item
    }

    fun timetable(section: String): List<TimetableSlot>? = sampleTimetables[section.uppercase()]

    private val sampleTimetables = mapOf(
        "CY-5A" to listOf(
            TimetableSlot("MON", "09:00", "10:00", "DevOps", "LHC-104"),
            TimetableSlot("MON", "10:00", "11:00", "Cryptography", "LHC-201"),
            TimetableSlot("TUE", "11:30", "13:30", "Network Security Lab", "CY-LAB-2"),
        ),
        "CY-5B" to listOf(
            TimetableSlot("MON", "11:30", "12:30", "DevOps", "LHC-105"),
            TimetableSlot("WED", "09:00", "10:00", "Cloud Security", "LHC-202"),
        ),
    )
}

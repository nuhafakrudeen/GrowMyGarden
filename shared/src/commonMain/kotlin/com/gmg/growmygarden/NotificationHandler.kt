package com.gmg.growmygarden

import com.tweener.alarmee.AlarmeeService
import com.tweener.alarmee.configuration.AlarmeePlatformConfiguration
import com.tweener.alarmee.createAlarmeeService
import kotlinx.datetime.DateTimePeriod
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.Month
import platform.posix.alarm

object NotificationHandler {
    private val alarmeeService = createAlarmeeService().apply {
        initialize(createAlarmeePlatformConfiguration())
    }

    private val localService = alarmeeService.local

    fun oneTimeNotif(id: String, title: String, body: String, date: LocalDateTime)
    {
        localService.schedule(
            alarmee = Alarmee(
                uuid = id,
                notificationTitle = title,
                notificationBody = body,
                scheduledDateTime = date,
                iosNotificationConfiguration = IosNotificationConfiguration(),
                )
        )
    }

}

internal expect fun createAlarmeePlatformConfiguration(): AlarmeePlatformConfiguration
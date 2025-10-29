package com.gmg.growmygarden

import com.tweener.alarmee.AlarmeeService
import com.tweener.alarmee.configuration.AlarmeePlatformConfiguration
import com.tweener.alarmee.model.IosNotificationConfiguration
import com.tweener.alarmee.createAlarmeeService
import com.tweener.alarmee.model.Alarmee
import com.tweener.alarmee.model.AndroidNotificationConfiguration
import com.tweener.alarmee.model.AndroidNotificationPriority
import com.tweener.alarmee.model.RepeatInterval
import kotlinx.datetime.DateTimePeriod
import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.Month
import platform.posix.alarm
import kotlin.time.Duration.Companion.minutes

object NotificationHandler {
    private val alarmeeService = createAlarmeeService().apply {
        initialize(createAlarmeePlatformConfiguration())
    }

    private val localService = alarmeeService.local

    fun setNotif(id: String, title: String, body: String, date: LocalDateTime, image: String?, delay: Int)
    {
        localService.schedule(
            alarmee = Alarmee(
                uuid = id,
                notificationTitle = title,
                notificationBody = body,
                scheduledDateTime = date,
                imageUrl = image,
                repeatInterval = RepeatInterval.Custom(duration = delay.minutes),
                androidNotificationConfiguration = AndroidNotificationConfiguration(
                    priority = AndroidNotificationPriority.HIGH,
                    channelId = "dailyNewsChannelId"
                ), //Will be honest, the code breaks without this
                iosNotificationConfiguration = IosNotificationConfiguration()
            )
        )
    }

    fun cancelAlarms(id: String)
    {
        if(id.isEmpty())
        {
            localService.cancelAll()
        }
        else
        {
            localService.cancel(uuid = id)
        }
    }


}

internal expect fun createAlarmeePlatformConfiguration(): AlarmeePlatformConfiguration
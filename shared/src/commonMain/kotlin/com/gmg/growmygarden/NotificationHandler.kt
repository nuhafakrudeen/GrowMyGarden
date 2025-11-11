package com.gmg.growmygarden

import com.tweener.alarmee.configuration.AlarmeePlatformConfiguration
import com.tweener.alarmee.createAlarmeeService
import com.tweener.alarmee.model.Alarmee
import com.tweener.alarmee.model.AndroidNotificationConfiguration
import com.tweener.alarmee.model.AndroidNotificationPriority
import com.tweener.alarmee.model.IosNotificationConfiguration
import com.tweener.alarmee.model.RepeatInterval
import kotlinx.datetime.LocalDateTime
import kotlin.time.Duration.Companion.minutes

class NotificationHandler {
    private val alarmeeService = createAlarmeeService().apply {
        initialize(createAlarmeePlatformConfiguration())
    }

    private val localService = alarmeeService.local

    fun setNotification(id: String, title: String, body: String, date: LocalDateTime, image: String?, delay: Long) {
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
                    channelId = "dailyNewsChannelId",
                ),
                iosNotificationConfiguration = IosNotificationConfiguration(),
            ),
        )
    }

    fun cancelNotification(id: String) {
        localService.cancel(uuid = id)
    }

    fun cancelAllNotifications() {
        localService.cancelAll()
    }
}

internal expect fun createAlarmeePlatformConfiguration(): AlarmeePlatformConfiguration

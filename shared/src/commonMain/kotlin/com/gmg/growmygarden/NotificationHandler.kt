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

/**
 * Class that handles the creation and deletion of notifications
 * Uses the Alarmee library
 */
class NotificationHandler {
    private val alarmeeService = createAlarmeeService().apply {
        initialize(createAlarmeePlatformConfiguration())
    }

    private val localService = alarmeeService.local

    /**
     * Creates a notification:
     * id: ID number of notification
     * title: Title of notification
     * body: Body text of notification
     * date: Time notification will start
     * image (optional): Image of notification
     * delay: delay between notifications
     */
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

    /**
     * Given an ID of a notification, cancel that notification
     */
    fun cancelNotification(id: String) {
        localService.cancel(uuid = id)
    }

    /**
     * Cancels all set notifications
     */
    fun cancelAllNotifications() {
        localService.cancelAll()
    }
}

/**
 * Expects a function to be created in iOSMain and androidMain (not used)
 * that configures Alarmee
 */
internal expect fun createAlarmeePlatformConfiguration(): AlarmeePlatformConfiguration

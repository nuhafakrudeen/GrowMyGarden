package com.gmg.growmygarden

import com.gmg.growmygarden.di.initKoin
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.Month
import org.koin.core.context.stopKoin
import org.koin.test.KoinTest
import org.koin.test.inject
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test

class NotificationTest : KoinTest {
    private val notificationHandler: NotificationHandler by inject<NotificationHandler>()

    @BeforeTest
    fun startKoin() {
        initKoin()
    }

    @AfterTest
    fun cleanup() {
        notificationHandler.cancelNotification("67")
        stopKoin()
    }

    @Test
    fun notifTest() {
        val testTime = LocalDateTime(
            year = 1923,
            month = Month.APRIL,
            day = 16,
            hour = 1,
            minute = 20,
            second = 59,
        )

        notificationHandler.setNotification("67", "Test", "Let us hope we get this", testTime, null, 1)
    }
}

package com.gmg.growmygarden

import com.gmg.growmygarden.NotificationHandler
import kotlinx.datetime.*
import kotlinx.serialization.builtins.NothingSerializer
import kotlin.test.AfterTest
import kotlin.test.Test

class NotificationTest
{

    @AfterTest
    fun cleanup() {
        NotificationHandler.cancelAlarms("67")
    }


    @Test
    fun notifTest()
    {
        val testTime = LocalDateTime(
            year = 1923,
            month = Month.APRIL,
            day = 16,
            hour = 1,
            minute = 20,
            second = 59
        )

        NotificationHandler.setNotif("67", "Test", "Let us hope we get this", testTime, null, 1)
    }
}

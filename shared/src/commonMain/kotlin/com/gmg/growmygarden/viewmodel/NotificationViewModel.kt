package com.gmg.growmygarden.viewmodel

import com.gmg.growmygarden.NotificationHandler
import com.rickclephas.kmp.nativecoroutines.NativeCoroutinesState
import com.rickclephas.kmp.observableviewmodel.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.datetime.LocalDateTime

class NotificationViewModel : ViewModel() {

    // Optional since this is just to view the state of the notifications
    @NativeCoroutinesState
    val commandLog = MutableStateFlow<String>("None")
    val commandHistory: StateFlow<String> get() = commandLog

    fun createNotification(id: String, title: String, body: String, date: LocalDateTime, image: String?, delay: Int) {
        NotificationHandler.setNotification(id, title, body, date, image, delay)
        commandLog.update { "Created New Notif: $title" }
    }

    fun cancelNotification(id: String) {
        NotificationHandler.cancelNotification(id)
        commandLog.update { "Cancelling Notification With ID $id" }
    }

    fun cancelAllNotifications() {
        NotificationHandler.cancelAllNotifications()
        commandLog.update { "Cancelling All Notifications" }
    }
}

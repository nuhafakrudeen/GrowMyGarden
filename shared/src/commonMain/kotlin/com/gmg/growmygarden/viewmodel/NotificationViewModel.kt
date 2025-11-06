package com.gmg.growmygarden.viewmodel

import com.gmg.growmygarden.NotificationHandler
import com.rickclephas.kmp.nativecoroutines.NativeCoroutinesState
import com.rickclephas.kmp.observableviewmodel.ViewModel
import kotlinx.datetime.LocalDateTime

//Could remove since it just shows some updates
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update



class NotificationViewModel : ViewModel(){

    //Optional since this is just to view the state of the notifications
    @NativeCoroutinesState
    private val commandLog = MutableStateFlow<String>("None")
    val commandHistory: StateFlow<String> get() = commandLog

    fun createNotification(id: String, title: String, body: String, date: LocalDateTime, image: String?, delay: Int)
    {
        NotificationHandler.setNotif(id, title, body, date, image, delay)
        commandLog.update { "Created New Notif: $title" }
    }

    fun cancelNotification(id: String)
    {
        NotificationHandler.cancelAlarms(id)
        if(id.isEmpty())
        {
            commandLog.update { "Cancelling All Notifications" }
        }
        else
        {
            commandLog.update { "Cancelling Notification With ID $id" }
        }
    }

}
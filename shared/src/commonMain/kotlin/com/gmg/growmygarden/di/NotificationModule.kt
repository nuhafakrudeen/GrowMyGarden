package di

import com.gmg.growmygarden.NotificationHandler
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module

val notificationModule = module {
    singleOf(::NotificationHandler)
}

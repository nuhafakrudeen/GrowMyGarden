package di

import com.gmg.growmygarden.network.PerenualApi
import com.gmg.growmygarden.network.createHttpClient
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module

val apiModule = module {
    single { createHttpClient(getProperty("perenualAPIKey")) }
    singleOf(::PerenualApi)
}

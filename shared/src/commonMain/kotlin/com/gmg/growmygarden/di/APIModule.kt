package di

import com.gmg.growmygarden.network.PerenualApi
import com.gmg.growmygarden.network.createHttpClient
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module

val apiModule = module {
    single { createHttpClient(getProperty("PERENUAL_API_KEY")) }
    singleOf(::PerenualApi)
    single {
        PerenualApi(
            client = get(),
            apiKey = getProperty("PERENUAL_API_KEY"),
        )
    }
}

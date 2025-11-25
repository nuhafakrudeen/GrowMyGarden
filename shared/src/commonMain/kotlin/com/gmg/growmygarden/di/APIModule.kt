package di

import com.gmg.growmygarden.network.PerenualApi
import com.gmg.growmygarden.network.createHttpClient
import com.gmg.growmygarden.util.getApiKey
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module

val apiModule = module {

    single { createHttpClient() }
    single<String> { getApiKey() }
    singleOf(::PerenualApi)
}

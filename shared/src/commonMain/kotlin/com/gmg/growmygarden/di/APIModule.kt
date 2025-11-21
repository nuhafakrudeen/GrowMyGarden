package di

import com.gmg.growmygarden.network.PerenualApi
import com.gmg.growmygarden.network.createHttpClient
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module

val apiModule = module {

    single { createHttpClient() }
    single<String> {"sk-pgtj691fe442b7c9f13588"}
    singleOf(::PerenualApi)
}


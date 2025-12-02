package com.gmg.growmygarden.di

import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.data.image.PlantScopeProvider
import com.gmg.growmygarden.data.source.PlantImageStore
import com.gmg.growmygarden.data.source.PlantRepository
import com.gmg.growmygarden.data.source.PlantInfoRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module
import kotlin.coroutines.CoroutineContext

val dataModule = module {
    // Execution context for background work
    single<CoroutineDispatcher> { Dispatchers.Default }
    single<CoroutineContext> { SupervisorJob() + get<CoroutineDispatcher>() }
    // ✅ Fix: provide CoroutineScope so PlantScopeProvider can be created
    single<CoroutineScope> { CoroutineScope(get<CoroutineContext>()) }

    // Database
    single { DatabaseProvider() }

    // Image/background pipeline
    // Koin will inject the CoroutineScope above into PlantScopeProvider
    singleOf(::PlantScopeProvider)
    singleOf(::PlantImageStore)

    // Repository
    singleOf(::PlantRepository)
    singleOf(::PlantInfoRepository)
}

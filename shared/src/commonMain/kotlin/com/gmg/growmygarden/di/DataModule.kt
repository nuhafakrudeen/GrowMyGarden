package com.gmg.growmygarden.di

import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.data.image.PlantScopeProvider
import com.gmg.growmygarden.data.source.PlantImageStore
import com.gmg.growmygarden.data.source.PlantInfoRepository
import com.gmg.growmygarden.data.source.PlantRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module
import kotlin.coroutines.CoroutineContext

val dataModule = module {
    single<CoroutineDispatcher> { Dispatchers.Default }
    single<CoroutineContext> { get<CoroutineDispatcher>() }
    single<CoroutineScope> { CoroutineScope(get<CoroutineContext>() + SupervisorJob()) }
    singleOf(::DatabaseProvider)

    singleOf(::PlantRepository)
    singleOf(::PlantInfoRepository)

    singleOf(::PlantScopeProvider)
    singleOf(::PlantImageStore)
}
package com.gmg.growmygarden.di

import com.gmg.growmygarden.viewmodel.DashboardViewModel
import org.koin.dsl.module
import di.dataModule
import org.koin.core.module.dsl.factoryOf

val viewModelModule = module {
    includes(dataModule)
    factoryOf(::DashboardViewModel)
}

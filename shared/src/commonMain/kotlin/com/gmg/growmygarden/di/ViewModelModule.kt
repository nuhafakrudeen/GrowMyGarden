package com.gmg.growmygarden.di

import com.gmg.growmygarden.viewmodel.DashboardViewModel
import di.dataModule
import org.koin.core.module.dsl.factoryOf
import org.koin.dsl.module

val viewModelModule = module {
    includes(dataModule)
    factoryOf(::DashboardViewModel)
}

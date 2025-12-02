package com.gmg.growmygarden.di

import com.gmg.growmygarden.viewmodel.DashboardViewModel
import org.koin.core.module.dsl.factoryOf
import org.koin.dsl.module

val viewModelModule = module {
    includes(dataModule)
    factoryOf(::DashboardViewModel)
}
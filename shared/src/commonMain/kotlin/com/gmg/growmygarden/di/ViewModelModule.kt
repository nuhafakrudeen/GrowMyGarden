package com.gmg.growmygarden.di

import com.gmg.growmygarden.viewmodel.DashboardViewModel
import com.gmg.growmygarden.viewmodel.LoginViewModel
import di.dataModule
import org.koin.core.module.dsl.factoryOf
import org.koin.dsl.module

val viewModelModule = module {
    includes(dataModule)
    includes(userModule)
    factoryOf(::DashboardViewModel)
    factoryOf(::LoginViewModel)
}

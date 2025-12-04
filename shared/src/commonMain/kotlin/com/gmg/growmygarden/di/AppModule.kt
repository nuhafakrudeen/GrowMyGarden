package com.gmg.growmygarden.di

import di.apiModule
import di.dataModule
import di.notificationModule
import di.viewModelModule

fun appModule() = listOf(
    dataModule,
    notificationModule,
    viewModelModule,
    apiModule,
)

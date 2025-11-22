package com.gmg.growmygarden.di

import di.apiModule
import di.dataModule
import di.notificationModule

fun appModule() = listOf(
    dataModule,
    notificationModule,
    viewModelModule,
    apiModule,
)

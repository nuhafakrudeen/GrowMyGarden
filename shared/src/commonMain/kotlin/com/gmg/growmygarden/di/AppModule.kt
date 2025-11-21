package com.gmg.growmygarden.di

import di.apiModule
import di.dataModule
import di.infoDataModule
import di.notificationModule

fun appModule() = listOf(
    dataModule,
    notificationModule,
    viewModelModule,
    infoDataModule,
    apiModule,
)

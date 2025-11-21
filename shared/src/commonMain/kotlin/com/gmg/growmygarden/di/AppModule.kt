package com.gmg.growmygarden.di

import di.apiModule
import di.dataModule
import di.notificationModule
import di.infoDataModule

fun appModule() = listOf(
    dataModule,
    notificationModule,
    viewModelModule,
    infoDataModule,
    apiModule
    )

package com.gmg.growmygarden.di

import di.apiModule

fun appModule() = listOf(
    dataModule,
    notificationModule,
    viewModelModule,
    apiModule,
)

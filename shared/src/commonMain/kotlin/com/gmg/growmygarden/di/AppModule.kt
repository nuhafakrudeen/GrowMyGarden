package com.gmg.growmygarden.di

import di.dataModule
import di.infoDataModule
import di.notificationModule

fun appModule() = listOf(dataModule, notificationModule, viewModelModule, infoDataModule)

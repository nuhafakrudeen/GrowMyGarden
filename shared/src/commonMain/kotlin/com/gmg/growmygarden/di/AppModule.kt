package com.gmg.growmygarden.di

import di.dataModule
import di.notificationModule

fun appModule() = listOf(dataModule, notificationModule)

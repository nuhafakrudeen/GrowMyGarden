package com.gmg.growmygarden.di

import org.koin.core.context.startKoin
//import org.koin.dsl.fileProperties

fun initKoin() {
    startKoin {
        modules(appModule())
//        fileProperties()
    }
}

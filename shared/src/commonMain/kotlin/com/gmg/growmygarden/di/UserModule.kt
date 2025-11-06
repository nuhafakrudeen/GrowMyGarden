package com.gmg.growmygarden.di

import com.gmg.growmygarden.auth.LoginService
import com.gmg.growmygarden.auth.UserAuthProvider
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module

val userModule = module {
    singleOf(::UserAuthProvider)
    factory { params -> LoginService(params.get(), get()) }
}

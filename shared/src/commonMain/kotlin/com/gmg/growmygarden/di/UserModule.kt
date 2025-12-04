package di

import com.gmg.growmygarden.auth.UserManager
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module

val userModule = module {
    singleOf(::UserManager)
}

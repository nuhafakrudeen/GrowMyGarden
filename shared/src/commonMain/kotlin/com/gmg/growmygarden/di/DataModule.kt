package di

import org.koin.dsl.module
import org.koin.core.module.dsl.singleOf
import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.data.source.PlantRepository

val dataModule = module {
    single { DatabaseProvider() }
    singleOf(::PlantRepository)
}


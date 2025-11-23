package di

import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.data.source.PlantInfoRepository
import com.gmg.growmygarden.data.source.PlantRepository
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module

val dataModule = module {
    single { DatabaseProvider() }
    singleOf(::PlantRepository)
    singleOf(::PlantInfoRepository)
}

package di

import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.data.source.PlantInfoRepository
import com.gmg.growmygarden.data.source.PlantRepository
import com.gmg.growmygarden.di.userModule
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module

val dataModule = module {
    includes(userModule)
    single { DatabaseProvider() }
    single { PlantRepository(get(), get(), getProperty("SYNC_ENDPOINT")) }
    singleOf(::PlantInfoRepository)
}

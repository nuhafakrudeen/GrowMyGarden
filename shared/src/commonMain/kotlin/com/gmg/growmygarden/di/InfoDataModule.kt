package di


import com.gmg.growmygarden.data.db.DatabaseProvider
import com.gmg.growmygarden.data.source.PlantInfoRepository
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module


val infoDataModule = module{
    single { DatabaseProvider() }
    singleOf(::PlantInfoRepository)
}
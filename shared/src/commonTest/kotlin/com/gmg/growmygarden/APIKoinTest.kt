package com.gmg.growmygarden

import com.gmg.growmygarden.network.PerenualApi
import di.apiModule
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.test.KoinTest
import org.koin.test.inject
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertNotNull

class APIKoinTest : KoinTest {

    @BeforeTest
    fun setupKoin() {
        startKoin {
            properties(
                mapOf(
                    "perenualAPIKey" to "FAKE_KEY",
                ),
            )
            modules(
                apiModule,
            )
        }
    }

    @Test
    fun instantiationTest() {
        val api: PerenualApi by inject()
        assertNotNull(api, "API Client was Null")
    }

    @AfterTest
    fun stop() {
        stopKoin()
    }
}

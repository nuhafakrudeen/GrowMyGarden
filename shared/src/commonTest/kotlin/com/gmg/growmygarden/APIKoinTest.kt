package com.gmg.growmygarden

import com.gmg.growmygarden.di.initKoin
import com.gmg.growmygarden.network.PerenualApi
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
        println("Starting Koin Init")
        initKoin()
        println("Koin Init Completed")
    }
    val api: PerenualApi by inject()

    @Test
    fun instantiationTest() {
        println("Api: $api")
        assertNotNull(api, "API Client was Null")
    }

    @AfterTest
    fun stop() {
        stopKoin()
    }
}

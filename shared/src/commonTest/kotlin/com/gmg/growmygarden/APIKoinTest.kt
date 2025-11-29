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
        initKoin()
    }
    val api: PerenualApi by inject<PerenualApi>()

    @Test
    fun instantiationTest() {
        assertNotNull(api)
    }

    @AfterTest
    fun stop() {
        stopKoin()
    }
}

package com.gmg.growmygarden

import com.gmg.growmygarden.di.getPropertiesMap
import kotlin.test.Test
import kotlin.test.assertNotNull

class SecretsTest {

    @Test
    fun getSecretsTest() {
        val secrets = getPropertiesMap()
        assert(secrets.isNotEmpty()) {"No Secrets Retrieved"}
        assertNotNull(secrets["PERENUAL_API_KEY"]) { "Secrets Did Not Contain Perenual API Key"}
        assert(((secrets["PERENUAL_API_KEY"] as String?)?.length ?: -1) > 0) { "Perenual API Key was Empty"}
    }
}
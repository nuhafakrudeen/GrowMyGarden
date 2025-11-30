package com.gmg.growmygarden

import com.gmg.growmygarden.di.getPropertiesMap
import kotlin.test.Test
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class SecretsTest {

    @Test
    fun getSecretsTest() {
        val secrets = getPropertiesMap()
        assertTrue(secrets.isNotEmpty(), "No Secrets Retrieved")
        val key = secrets["PERENUAL_API_KEY"]
        assertNotNull(key, "Secrets Did Not Contain Perenual API Key")
        assertTrue((key as String?)?.isNotEmpty() ?: false, "Perenual API Key was Empty")
    }
}

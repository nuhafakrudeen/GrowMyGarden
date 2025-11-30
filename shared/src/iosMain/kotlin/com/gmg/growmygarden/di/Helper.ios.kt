package com.gmg.growmygarden.di

import kotlinx.cinterop.toKString
import platform.Foundation.NSBundle
import platform.Foundation.NSString
import platform.Foundation.NSUTF8StringEncoding
import platform.Foundation.stringWithContentsOfFile
import platform.posix.getenv

actual fun getPropertiesMap(): Map<String, Any> {
    val fileName = "koin"
    val type = "properties"
    val path =
        NSBundle.mainBundle.pathForResource(fileName, ofType = type) ?: NSBundle.allBundles.map { it as NSBundle }
            .firstNotNullOfOrNull { it.pathForResource(fileName, ofType = type) }
            ?: return getPropertiesFromEnv()

    val contents = NSString.stringWithContentsOfFile(path, encoding = NSUTF8StringEncoding, error = null)
        ?: return getPropertiesFromEnv()
    return contents.lines().map {
        it.split("=", limit = 2)
    }.filter {
        it.size == 2
    }.associate { (key, value) ->
        key.trim() to value.trim()
    }
}

private fun getPropertiesFromEnv(): Map<String, Any> {
    val key = getenv("PERENUAL_API_KEY")?.toKString()
    println("KMP PERENUAL_API_KEY: ${key?.length ?: -1} chars")
    return buildMap {
        put("perenualAPIKey", key ?: "")
    }
}

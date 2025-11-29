package com.gmg.growmygarden.di

import platform.Foundation.NSBundle
import platform.Foundation.NSString
import platform.Foundation.NSUTF8StringEncoding
import platform.Foundation.stringWithContentsOfFile

actual fun getPropertiesMap(): Map<String, Any> {
    val fileName = "koin"
    val type = "properties"
    return (
        NSBundle.mainBundle.pathForResource("resources/$fileName", ofType = type) ?: NSBundle.allBundles.map { it as NSBundle }
            .firstNotNullOfOrNull { it.pathForResource(fileName, ofType = type) }
        )?.let { path ->
        NSString.stringWithContentsOfFile(path, encoding = NSUTF8StringEncoding, error = null)?.lines()?.map {
            it.split("=", limit = 2)
        }?.filter {
            it.size == 2
        }?.associate { (key, value) ->
            key.trim() to value.trim()
        }
    } ?: emptyMap()
}

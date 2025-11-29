package com.gmg.growmygarden.di

import platform.Foundation.NSBundle
import platform.Foundation.NSString
import platform.Foundation.NSUTF8StringEncoding
import platform.Foundation.stringWithContentsOfFile

actual fun getPropertiesMap(): Map<String, Any> {
    return NSBundle.mainBundle.pathForResource("koin", "properties")?.let { path ->
        NSString.stringWithContentsOfFile(path, encoding = NSUTF8StringEncoding, error = null)?.lines()?.map {
            it.split("=", limit = 2)
        }?.filter {
            it.size == 2
        }?.associate { (key, value) ->
            key to value
        }
    } ?: emptyMap()
}

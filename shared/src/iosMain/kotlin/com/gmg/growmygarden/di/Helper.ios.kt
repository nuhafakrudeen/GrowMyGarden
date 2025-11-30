package com.gmg.growmygarden.di

import kotlinx.cinterop.toKString
import platform.Foundation.NSBundle
import platform.Foundation.NSDictionary
import platform.Foundation.dictionaryWithContentsOfFile
import platform.posix.getenv

actual fun getPropertiesMap(): Map<String, Any> {
    return NSBundle.mainBundle.pathForResource("Secrets", ofType = "plist")?.let { path ->

        val contents = NSDictionary.dictionaryWithContentsOfFile(path)
         contents?.let {
            buildMap {
                for ((k, v) in it) {
                    put(k as String, v ?: "")
                }
            }
        }
    } ?: emptyMap()
}

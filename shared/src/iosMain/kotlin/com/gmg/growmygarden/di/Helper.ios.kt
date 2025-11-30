package com.gmg.growmygarden.di

import androidx.compose.runtime.TestOnly
import platform.Foundation.NSBundle
import platform.Foundation.NSDictionary
import platform.Foundation.NSFileManager
import platform.Foundation.dictionaryWithContentsOfFile

actual fun getPropertiesMap(): Map<String, Any> {
    return NSBundle.mainBundle.pathForResource("Secrets", ofType = "plist")?.let { path ->

        val contents = NSDictionary.dictionaryWithContentsOfFile(path)

        contents?.let {
            buildMap {
                for ((k, v) in it) {
                    put(k as String, v ?: "")
                }
            }
        } ?: run {
            println("Failed to load Contents of File")
            loadSecretsFromFileSystem()
        }
    } ?: run {
        println("Failed to Find Secrets File")
        loadSecretsFromFileSystem()
    }
}

@TestOnly
actual fun loadSecretsFromFileSystem(): Map<String, Any> {
    val cwd = NSFileManager.defaultManager.currentDirectoryPath
    val path = "$cwd/shared/Secrets.plist"

    val contents = NSDictionary.dictionaryWithContentsOfFile(path)

    return contents?.let {
        buildMap {
            for ((k, v) in it) {
                put(k as String, v ?: "")
            }
        }
    } ?: run {
        println("Failed to load Contents of File (cwd)")
        emptyMap()
    }
}

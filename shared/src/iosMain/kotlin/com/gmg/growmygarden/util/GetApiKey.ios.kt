package com.gmg.growmygarden.util

import platform.Foundation.NSBundle
import platform.Foundation.NSString
import platform.Foundation.NSUTF8StringEncoding
import platform.Foundation.stringWithContentsOfFile

actual fun getApiKey(): String {
    val path = NSBundle.mainBundle.pathForResource("koin", "properties")
        ?: return ""
    val content = NSString.stringWithContentsOfFile(path, encoding = NSUTF8StringEncoding, error = null)
        ?: return ""
    val parts = content.split("=")
    return if (parts.size == 2) parts[1].trim() else ""
}

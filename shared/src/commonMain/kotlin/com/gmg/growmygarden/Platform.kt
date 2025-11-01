package com.gmg.growmygarden

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform

package com.gmg.growmygarden

import com.tweener.alarmee.configuration.AlarmeePlatformConfiguration

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform

expect fun createAlarmeePlatformConfiguration(): AlarmeePlatformConfiguration
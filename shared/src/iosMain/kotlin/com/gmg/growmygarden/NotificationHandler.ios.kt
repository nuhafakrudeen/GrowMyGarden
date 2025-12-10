package com.gmg.growmygarden

import com.tweener.alarmee.configuration.AlarmeeIosPlatformConfiguration
import com.tweener.alarmee.configuration.AlarmeePlatformConfiguration

/**
 * Function that configure Alarmee on ios platforms
 */
internal actual fun createAlarmeePlatformConfiguration(): AlarmeePlatformConfiguration =
    AlarmeeIosPlatformConfiguration

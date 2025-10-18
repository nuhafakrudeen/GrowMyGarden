package com.gmg.growmygarden

import com.tweener.alarmee.configuration.AlarmeeIosPlatformConfiguration
import com.tweener.alarmee.configuration.AlarmeePlatformConfiguration


internal actual fun createAlarmeePlatformConfiguration(): AlarmeePlatformConfiguration =
    AlarmeeIosPlatformConfiguration
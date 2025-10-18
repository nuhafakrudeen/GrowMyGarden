package com.gmg.growmygarden

import com.tweener.alarmee.configuration.AlarmeeIosPlatformConfiguration
import com.tweener.alarmee.configuration.AlarmeePlatformConfiguration
import platform.UIKit.UIDevice

class IOSPlatform : Platform {
    override val name: String = UIDevice.currentDevice.systemName() + " " + UIDevice.currentDevice.systemVersion
}

actual fun getPlatform(): Platform = IOSPlatform()

actual fun createAlarmeePlatformConfiguration(): AlarmeePlatformConfiguration
{
    return AlarmeeIosPlatformConfiguration
}

//val platformConfiguration: AlarmeePlatformConfiguration = AlarmeeIosPlatformConfiguration
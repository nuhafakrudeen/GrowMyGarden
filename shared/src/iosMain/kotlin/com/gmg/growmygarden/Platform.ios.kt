package com.gmg.growmygarden

import com.tweener.alarmee.AlarmeeService
import com.tweener.alarmee.configuration.AlarmeeIosPlatformConfiguration
import com.tweener.alarmee.configuration.AlarmeePlatformConfiguration
import com.tweener.alarmee.rememberAlarmeeService
import platform.UIKit.UIDevice

class IOSPlatform : Platform {
    override val name: String = UIDevice.currentDevice.systemName() + " " + UIDevice.currentDevice.systemVersion
}

actual fun getPlatform(): Platform = IOSPlatform()







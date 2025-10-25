import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.spotless)
    alias(libs.plugins.kmp.nativecoroutines)
    alias(libs.plugins.ksp)
    alias(libs.plugins.kotlinx.serialization)
}

kotlin {
//    androidTarget {
//        compilerOptions {
//            jvmTarget.set(JvmTarget.JVM_11)
//        }
//    }

    iosArm64 {
        binaries {
            framework {
                baseName = "Shared"
                isStatic = true
                binaryOption("bundleId", "com.gmg.growmygarden.shared")
                val path = "$rootDir/vendor/CouchbaseLite/CouchbaseLite.xcframework/ios-arm64"
                linkerOpts("-F$path", "-framework", "CouchbaseLite", "-rpath", path)
            }

            getTest("DEBUG").apply {
                val path = "$rootDir/vendor/CouchbaseLite.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$path", "-framework", "CouchbaseLite", "-rpath", path)
            }
        }
    }

    iosSimulatorArm64 {
        binaries {
            framework {
                baseName = "Shared"
                val path = "$rootDir/vendor/CouchbaseLite/CouchbaseLite.xcframework/ios-arm64_x86_64-simulator"
                isStatic = true
                binaryOption("bundleId", "com.gmg.growmygarden.shared")
                linkerOpts("-F$path", "-framework", "CouchbaseLite", "-rpath", path)
            }
            getTest("DEBUG").apply {
                val path = "$rootDir/vendor/CouchbaseLite.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$path", "-framework", "CouchbaseLite", "-rpath", path)
            }
        }
    }

    sourceSets {
        all {
            languageSettings.optIn("kotlinx.cinterop.ExperimentalForeignApi")
            languageSettings.optIn("kotlin.experimental.ExperimentalObjCName")
        }
        commonMain.dependencies {
            // put your Multiplatform dependencies here
            implementation(libs.kotbase.ktx)
            implementation(libs.koin.core)
            implementation(libs.kotlinx.serialization.json)
            api(libs.androidx.lifecycle.runtimeCompose)
        }
        commonTest.dependencies {
            implementation(libs.kotlin.test)
            implementation(libs.koin.core)
            implementation(libs.koin.test)
            implementation(libs.androidx.coroutine.test)
        }
        iosTest.dependencies {

        }

    }
}

tasks.withType<AbstractTestTask> {
    testLogging {
        events("passed", "skipped", "failed", "standardOut", "standardError")
        exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
        showExceptions = true
        showCauses = true
        showStackTraces = true
    }
}

spotless {
    kotlin {
        // version, editorConfigPath, editorConfigOverride and customRuleSets are all optional
        ktlint(libs.versions.ktlint.asProvider().get()).editorConfigOverride(
            mapOf(
                "indent_size" to 2,
                // intellij_idea is the default style we preset in Spotless, you can override it referring to https://pinterest.github.io/ktlint/latest/rules/code-styles.
                "ktlint_code_style" to "intellij_idea",
            )
        ).customRuleSets(
            listOf(
                libs.ktlint.rules.get().toString()
            )
        )
    }
}

//android {
//    namespace = "com.gmg.growmygarden.shared"
//    compileSdk = libs.versions.android.compileSdk.get().toInt()
//    compileOptions {
//        sourceCompatibility = JavaVersion.VERSION_11
//        targetCompatibility = JavaVersion.VERSION_11
//    }
//    defaultConfig {
//        minSdk = libs.versions.android.minSdk.get().toInt()
//    }
//}

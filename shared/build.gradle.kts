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
        binaries.framework {
            baseName = "Shared"
            isStatic = true
            val path = "$rootDir/vendor/CouchbaseLite/CouchbaseLiteSwift.xcframework/ios-arm64"
            linkerOpts("-F$path", "-framework", "CouchbaseLiteSwift", "-rpath", path)
//            export(libs.androidx.lifecycle.viewmodel)
        }
    }

    iosSimulatorArm64 {
        binaries.framework {
            baseName = "shared"
            val path = "$rootDir/vendor/CouchbaseLite/CouchbaseLiteSwift.xcframework/ios-arm64_x86_64-simulator"
            linkerOpts("-F$path", "-framework", "CouchbaseLiteSwift", "-rpath", path)
//            export(libs.androidx.lifecycle.viewmodel)
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
//            api(libs.androidx.lifecycle.viewmodel)
            api(libs.kmp.observableviewmodel.core.get().toString()) {
                exclude(group = "androidx.lifecycle")
                exclude(group = "androidx.annotation")
                exclude(group = "androidx.collection")
            }
            api(libs.androidx.lifecycle.runtimeCompose)
        }
        commonTest.dependencies {
            implementation(libs.kotlin.test)
            implementation(libs.koin.core)
            implementation(libs.koin.test)
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

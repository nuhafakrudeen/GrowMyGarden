import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.spotless)
    alias(libs.plugins.kmp.nativecoroutines)
    alias(libs.plugins.ksp)
    alias(libs.plugins.kotlinx.serialization)
    alias(libs.plugins.composeMultiplatform)
    alias(libs.plugins.composeCompiler)
}

kotlin {

    applyDefaultHierarchyTemplate()

    compilerOptions {
        freeCompilerArgs.add("-Xexpect-actual-classes")
    }
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
                export(libs.androidx.lifecycle.viewmodel)
                export(libs.kmp.observableviewmodel.core)
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
                export(libs.androidx.lifecycle.viewmodel)
                export(libs.kmp.observableviewmodel.core)
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
            languageSettings.optIn("kotlin.experimental.ExperimentalNativeApi")
            languageSettings.optIn("kotlin.uuid.ExperimentalUuidApi")
        }
        commonMain.dependencies {
            // put your Multiplatform dependencies here
            implementation(libs.kotbase.ktx)
            implementation(libs.koin.core)
            implementation(libs.koin.compose)
            implementation(libs.kotlinx.serialization.json)
            implementation(libs.filekit.core)
            implementation(libs.filekit.dialogs)
            api(libs.androidx.lifecycle.viewmodel)
            api(libs.kmp.observableviewmodel.core)
            implementation(libs.alarmee)

            implementation(libs.bundles.ktor)

        }
        commonTest.dependencies {
            implementation(libs.kotlin.test)
            implementation(libs.koin.core)
            implementation(libs.koin.test)
            implementation(libs.androidx.coroutine.test)
            implementation(libs.moko.permissions.test)
        }

        iosMain.dependencies {
            implementation(libs.ktor.client.darwin)
            api(libs.kmp.observableviewmodel.core)

        }
        iosTest.dependencies {
            implementation(libs.alarmee)
            api(libs.moko.permissions)
            implementation(libs.moko.permissions.notifications)
            api(libs.moko.permissions.compose)

        }

    }
}

tasks.withType<AbstractTestTask> {
    testLogging {
        events("passed", "skipped", "failed", "standardOut", "standardError")
        exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
        showExceptions = true
        showCauses = false
        showStackTraces = false
    }
}

spotless {
    kotlin {
        target("src/**/*.kt")
        targetExclude("build/**/*.kt")
        targetExclude("src/androidMain/**/*.kt")
        // version, editorConfigPath, editorConfigOverride and customRuleSets are all optional
        ktlint(libs.versions.ktlint.asProvider().get()).editorConfigOverride(
            mapOf(
                "indent_size" to 4,
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

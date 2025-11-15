import org.gradle.internal.os.OperatingSystem

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

                val couchbasePath = "$rootDir/vendor/CouchbaseLite/CouchbaseLite.xcframework/ios-arm64"
                linkerOpts("-F$couchbasePath", "-framework", "CouchbaseLite", "-rpath", couchbasePath)

                val firebaseRoot = "$rootDir/vendor/Firebase"

                val firebaseCorePath = "$firebaseRoot/FirebaseAnalytics/FirebaseCore.xcframework/ios-arm64"
                linkerOpts("-F$firebaseCorePath", "-framework", "FirebaseCore", "-rpath", firebaseCorePath)

                val firebaseAuthPath = "$firebaseRoot/FirebaseAuth/FirebaseAuth.xcframework/ios-arm64"
                linkerOpts("-F$firebaseAuthPath", "-framework", "FirebaseAuth", "-rpath", firebaseAuthPath)


                val firebaseAuthInteropPath = "$firebaseRoot/FirebaseAuth/FirebaseAuthInterop.xcframework/ios-arm64"
                linkerOpts(
                    "-F$firebaseAuthInteropPath",
                    "-framework",
                    "FirebaseAuthInterop",
                    "-rpath",
                    firebaseAuthInteropPath
                )

                val firebaseAppCheckInteropPath =
                    "$firebaseRoot/FirebaseAppCheck/FirebaseAppCheckInterop.xcframework/ios-arm64"
                linkerOpts(
                    "-F$firebaseAppCheckInteropPath",
                    "-framework",
                    "FirebaseAppCheckInterop",
                    "-rpath",
                    firebaseAppCheckInteropPath
                )

                val firebaseCoreExtensionPath = "$firebaseRoot/FirebaseAuth/FirebaseCoreExtension.xcframework/ios-arm64"
                linkerOpts(
                    "-F$firebaseCoreExtensionPath",
                    "-framework",
                    "FirebaseCoreExtension",
                    "-rpath",
                    firebaseCoreExtensionPath
                )

                val firebaseCoreInternalPath =
                    "$firebaseRoot/FirebaseAnalytics/FirebaseCoreInternal.xcframework/ios-arm64"
                linkerOpts(
                    "-F$firebaseCoreInternalPath",
                    "-framework",
                    "FirebaseCoreInternal",
                    "-rpath",
                    firebaseCoreInternalPath
                )

                val gtmSessionFetcherPath = "$firebaseRoot/FirebaseAuth/GTMSessionFetcher.xcframework/ios-arm64"
                linkerOpts(
                    "-F$gtmSessionFetcherPath",
                    "-framework",
                    "GTMSessionFetcher",
                    "-rpath",
                    gtmSessionFetcherPath
                )

                val googleUtilitiesPath = "$firebaseRoot/FirebaseAnalytics/GoogleUtilities.xcframework/ios-arm64"
                linkerOpts("-F$googleUtilitiesPath", "-framework", "GoogleUtilities", "-rpath", googleUtilitiesPath)

                val recaptchaInteropPath = "$firebaseRoot/FirebaseAuth/RecaptchaInterop.xcframework/ios-arm64"
                linkerOpts("-F$recaptchaInteropPath", "-framework", "RecaptchaInterop", "-rpath", recaptchaInteropPath)



                export(libs.androidx.lifecycle.viewmodel)
                export(libs.kmp.observableviewmodel.core)
            }

            getTest("DEBUG").apply {
                val couchbasePath = "$rootDir/vendor/CouchbaseLite.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$couchbasePath", "-framework", "CouchbaseLite", "-rpath", couchbasePath)

                val firebaseRoot = "$rootDir/vendor/Firebase"

                val firebaseCorePath =
                    "$firebaseRoot/FirebaseAnalytics/FirebaseCore.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$firebaseCorePath", "-framework", "FirebaseCore", "-rpath", firebaseCorePath)

                val firebaseAuthPath = "$firebaseRoot/FirebaseAuth/FirebaseAuth.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$firebaseAuthPath", "-framework", "FirebaseAuth", "-rpath", firebaseAuthPath)

                val firebaseAuthInteropPath =
                    "$firebaseRoot/FirebaseAuth/FirebaseAuthInterop.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$firebaseAuthInteropPath",
                    "-framework",
                    "FirebaseAuthInterop",
                    "-rpath",
                    firebaseAuthInteropPath
                )

                val firebaseAppCheckInteropPath =
                    "$firebaseRoot/FirebaseAppCheck/FirebaseAppCheckInterop.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$firebaseAppCheckInteropPath",
                    "-framework",
                    "FirebaseAppCheckInterop",
                    "-rpath",
                    firebaseAppCheckInteropPath
                )

                val firebaseCoreExtensionPath =
                    "$firebaseRoot/FirebaseAuth/FirebaseCoreExtension.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$firebaseCoreExtensionPath",
                    "-framework",
                    "FirebaseCoreExtension",
                    "-rpath",
                    firebaseCoreExtensionPath
                )

                val firebaseCoreInternalPath =
                    "$firebaseRoot/FirebaseAnalytics/FirebaseCoreInternal.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$firebaseCoreInternalPath",
                    "-framework",
                    "FirebaseCoreInternal",
                    "-rpath",
                    firebaseCoreInternalPath
                )

                val gtmSessionFetcherPath =
                    "$firebaseRoot/FirebaseAuth/GTMSessionFetcher.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$gtmSessionFetcherPath",
                    "-framework",
                    "GTMSessionFetcher",
                    "-rpath",
                    gtmSessionFetcherPath
                )

                val googleUtilitiesPath =
                    "$firebaseRoot/FirebaseAnalytics/GoogleUtilities.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$googleUtilitiesPath", "-framework", "GoogleUtilities", "-rpath", googleUtilitiesPath)

                val recaptchaInteropPath =
                    "$firebaseRoot/FirebaseAuth/RecaptchaInterop.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$recaptchaInteropPath", "-framework", "RecaptchaInterop", "-rpath", recaptchaInteropPath)


            }
        }
    }

    iosSimulatorArm64 {
        binaries {
            framework {
                baseName = "Shared"
                val couchbasePath = "$rootDir/vendor/CouchbaseLite/CouchbaseLite.xcframework/ios-arm64_x86_64-simulator"
                isStatic = true

                binaryOption("bundleId", "com.gmg.growmygarden.shared")
                linkerOpts("-F$couchbasePath", "-framework", "CouchbaseLite", "-rpath", couchbasePath)

                val firebaseRoot = "$rootDir/vendor/Firebase"

                val firebaseCorePath =
                    "$firebaseRoot/FirebaseAnalytics/FirebaseCore.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$firebaseCorePath", "-framework", "FirebaseCore", "-rpath", firebaseCorePath)

                val firebaseAuthPath = "$firebaseRoot/FirebaseAuth/FirebaseAuth.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$firebaseAuthPath", "-framework", "FirebaseAuth", "-rpath", firebaseAuthPath)

                val firebaseAuthInteropPath =
                    "$firebaseRoot/FirebaseAuth/FirebaseAuthInterop.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$firebaseAuthInteropPath",
                    "-framework",
                    "FirebaseAuthInterop",
                    "-rpath",
                    firebaseAuthInteropPath
                )

                val firebaseAppCheckInteropPath =
                    "$firebaseRoot/FirebaseAppCheck/FirebaseAppCheckInterop.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$firebaseAppCheckInteropPath",
                    "-framework",
                    "FirebaseAppCheckInterop",
                    "-rpath",
                    firebaseAppCheckInteropPath
                )

                val firebaseCoreExtensionPath =
                    "$firebaseRoot/FirebaseAuth/FirebaseCoreExtension.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$firebaseCoreExtensionPath",
                    "-framework",
                    "FirebaseCoreExtension",
                    "-rpath",
                    firebaseCoreExtensionPath
                )

                val firebaseCoreInternalPath =
                    "$firebaseRoot/FirebaseAnalytics/FirebaseCoreInternal.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$firebaseCoreInternalPath",
                    "-framework",
                    "FirebaseCoreInternal",
                    "-rpath",
                    firebaseCoreInternalPath
                )

                val gtmSessionFetcherPath =
                    "$firebaseRoot/FirebaseAuth/GTMSessionFetcher.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$gtmSessionFetcherPath",
                    "-framework",
                    "GTMSessionFetcher",
                    "-rpath",
                    gtmSessionFetcherPath
                )

                val googleUtilitiesPath =
                    "$firebaseRoot/FirebaseAnalytics/GoogleUtilities.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$googleUtilitiesPath", "-framework", "GoogleUtilities", "-rpath", googleUtilitiesPath)

                val recaptchaInteropPath =
                    "$firebaseRoot/FirebaseAuth/RecaptchaInterop.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$recaptchaInteropPath", "-framework", "RecaptchaInterop", "-rpath", recaptchaInteropPath)



                export(libs.androidx.lifecycle.viewmodel)
                export(libs.kmp.observableviewmodel.core)
            }

            getTest("DEBUG").apply {
                val couchbasePath = "$rootDir/vendor/CouchbaseLite.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$couchbasePath", "-framework", "CouchbaseLite", "-rpath", couchbasePath)

                val firebaseRoot = "$rootDir/vendor/Firebase"

                val firebaseCorePath =
                    "$firebaseRoot/FirebaseAnalytics/FirebaseCore.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$firebaseCorePath", "-framework", "FirebaseCore", "-rpath", firebaseCorePath)

                val firebaseAuthPath = "$firebaseRoot/FirebaseAuth/FirebaseAuth.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$firebaseAuthPath", "-framework", "FirebaseAuth", "-rpath", firebaseAuthPath)

                val firebaseAuthInteropPath =
                    "$firebaseRoot/FirebaseAuth/FirebaseAuthInterop.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$firebaseAuthInteropPath",
                    "-framework",
                    "FirebaseAuthInterop",
                    "-rpath",
                    firebaseAuthInteropPath
                )

                val firebaseAppCheckInteropPath =
                    "$firebaseRoot/FirebaseAppCheck/FirebaseAppCheckInterop.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$firebaseAppCheckInteropPath",
                    "-framework",
                    "FirebaseAppCheckInterop",
                    "-rpath",
                    firebaseAppCheckInteropPath
                )

                val firebaseCoreExtensionPath =
                    "$firebaseRoot/FirebaseAuth/FirebaseCoreExtension.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$firebaseCoreExtensionPath",
                    "-framework",
                    "FirebaseCoreExtension",
                    "-rpath",
                    firebaseCoreExtensionPath
                )

                val firebaseCoreInternalPath =
                    "$firebaseRoot/FirebaseAnalytics/FirebaseCoreInternal.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$firebaseCoreInternalPath",
                    "-framework",
                    "FirebaseCoreInternal",
                    "-rpath",
                    firebaseCoreInternalPath
                )

                val gtmSessionFetcherPath =
                    "$firebaseRoot/FirebaseAuth/GTMSessionFetcher.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts(
                    "-F$gtmSessionFetcherPath",
                    "-framework",
                    "GTMSessionFetcher",
                    "-rpath",
                    gtmSessionFetcherPath
                )

                val googleUtilitiesPath =
                    "$firebaseRoot/FirebaseAnalytics/GoogleUtilities.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$googleUtilitiesPath", "-framework", "GoogleUtilities", "-rpath", googleUtilitiesPath)

                val recaptchaInteropPath =
                    "$firebaseRoot/FirebaseAuth/RecaptchaInterop.xcframework/ios-arm64_x86_64-simulator"
                linkerOpts("-F$recaptchaInteropPath", "-framework", "RecaptchaInterop", "-rpath", recaptchaInteropPath)

                if (OperatingSystem.current().isMacOsX) {
                    val swiftRuntimeDir = providers.exec {
                        commandLine("xcode-select", "-p")
                    }.standardOutput.asText.map { devPath ->
                        File(devPath.trim())
                            .resolve("Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator")
                            .absolutePath
                    }

                    // Add -L<swiftRuntimeDir> and explicitly link compatibility libs
//                    linkerOpts(
//                        "-L${swiftRuntimeDir.get()}",
//                        "-lswiftCompatibility56",
//                        "-lswiftCompatibilityPacks",
//                        "-lswift_Builtin_float",
//                        "-lswift_errno",
//                        "-lswift_math",
//                        "-lswift_signal",
//                        "-lswift_stdio",
//                        "-lswift_time",
//                        "-lswiftsys_time",
//                        "-lswiftunistd",
//                    )
                }
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
            implementation(libs.kotbase.kermit)
            implementation(libs.koin.core)
            implementation(libs.koin.compose)
            implementation(libs.kotlinx.serialization.json)
            implementation(libs.filekit.core)
            implementation(libs.filekit.dialogs)

            implementation(libs.firebase.auth)
            implementation(libs.firebase.app)
            implementation(libs.kermit)
            api(libs.androidx.lifecycle.viewmodel)
            api(libs.kmp.observableviewmodel.core)
            implementation(libs.alarmee)
        }
        commonTest.dependencies {
            implementation(libs.kotlin.test)
            implementation(libs.koin.core)
            implementation(libs.koin.test)
            implementation(libs.androidx.coroutine.test)
            implementation(libs.moko.permissions.test)
        }

        iosMain.dependencies {
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

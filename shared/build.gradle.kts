import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.spotless)
    alias(libs.plugins.composeMultiplatform)
    alias(libs.plugins.composeCompiler)
//    alias(libs.plugins.androidLibrary)
}

kotlin {
//    androidTarget {
//        compilerOptions {
//            jvmTarget.set(JvmTarget.JVM_11)
//        }
//    }

    listOf(
        iosArm64(),
        iosSimulatorArm64()
    ).forEach { iosTarget ->
        iosTarget.binaries.framework {
            baseName = "Shared"
            isStatic = true
        }
    }


    sourceSets {
        commonMain.dependencies {
            // Added a few implementations for notification system
            implementation(compose.runtime)
            implementation(compose.foundation)
            implementation(compose.material)
            implementation(compose.ui)
            implementation(compose.components.resources)
            implementation(libs.androidx.compose.uiToolingsPreview)
            implementation(libs.androidx.lifecycle.viewmodelCompose)
            implementation(libs.androidx.lifecycle.runtimeCompose)

            //Libraries
            implementation(compose.material3)
            implementation(libs.koin.compose)
            api(libs.koin.core)

            implementation(libs.alarmee)

        }
        commonTest.dependencies {
            implementation(libs.kotlin.test)
        }

    }

}

repositories {
    mavenCentral() // For Spotless
}
spotless {
  kotlin {
    // version, editorConfigPath, editorConfigOverride and customRuleSets are all optional
    ktlint(libs.versions.ktlint.asProvider().get())
      .editorConfigOverride(
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

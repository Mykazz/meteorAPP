plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // <- fix plugin id
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.asteroidsim"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Java 17 for Java sources
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Java 17 for Kotlin
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.asteroidsim"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ⛔ REMOVE this (do NOT keep in module):
// java {
//     toolchain {
//         languageVersion = JavaLanguageVersion.of(17)
//     }
// }

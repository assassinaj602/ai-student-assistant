plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.ai_student_assistant"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.ai_student_assistant"
        // Firebase Auth 23.x requires minSdk 23+
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        // Enable support for newer Java language APIs on older Android versions
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // Use JVM 11 target to match Kotlin plugin compatibility
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
}

dependencies {
    // Required when using Java 8+ APIs with minSdk < 26
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}

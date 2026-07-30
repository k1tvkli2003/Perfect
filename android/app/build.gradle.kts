plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

val privateKeystorePath =
    providers.environmentVariable("PERFECT_ANDROID_KEYSTORE_PATH").orNull
val privateKeystorePassword =
    providers.environmentVariable("PERFECT_ANDROID_KEYSTORE_PASSWORD").orNull
val privateKeyAlias =
    providers.environmentVariable("PERFECT_ANDROID_KEY_ALIAS").orNull
val privateKeyPassword =
    providers.environmentVariable("PERFECT_ANDROID_KEY_PASSWORD").orNull
val privateSigningValues =
    listOf(
        privateKeystorePath,
        privateKeystorePassword,
        privateKeyAlias,
        privateKeyPassword,
    )
val hasAnyPrivateReleaseSigning =
    privateSigningValues.any { !it.isNullOrBlank() }
val hasPrivateReleaseSigning =
    privateSigningValues.all { !it.isNullOrBlank() }

require(!hasAnyPrivateReleaseSigning || hasPrivateReleaseSigning) {
    "Perfect private Android signing is only partially configured. " +
        "Provide the complete stable JKS path/password/alias/key-password set " +
        "or remove all four values for a local verification-only build."
}

android {
    namespace = "com.k1tvkli2003.perfect"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Scheduled reminders use java.time through flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.k1tvkli2003.perfect"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasPrivateReleaseSigning) {
            create("privateRelease") {
                storeFile = file(privateKeystorePath!!)
                storePassword = privateKeystorePassword
                keyAlias = privateKeyAlias
                keyPassword = privateKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // CI supplies a stable private key through environment-backed
            // GitHub secrets. Local verification remains buildable with the
            // debug key and never requires committing signing material.
            signingConfig =
                if (hasPrivateReleaseSigning) {
                    signingConfigs.getByName("privateRelease")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

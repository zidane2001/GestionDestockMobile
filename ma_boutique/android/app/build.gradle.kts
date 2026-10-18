import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Signature de production lue dans android/key.properties (fichier ignoré par
// Git, comme le keystore). Absent — autre machine, intégration continue — le
// build retombe sur la clé debug pour ne pas échouer.
val fichierCle = rootProject.file("key.properties")
val proprietesCle = Properties().apply {
    if (fichierCle.exists()) fichierCle.inputStream().use { load(it) }
}

android {
    namespace = "com.example.ma_boutique"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.ma_boutique"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (fichierCle.exists()) {
            create("release") {
                keyAlias = proprietesCle["keyAlias"] as String
                keyPassword = proprietesCle["keyPassword"] as String
                storeFile = file(proprietesCle["storeFile"] as String)
                storePassword = proprietesCle["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Le keystore de production signe les APK distribués : sans lui, les
            // mises à jour ne pourraient pas s'installer par-dessus les précédentes.
            signingConfig = if (fichierCle.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

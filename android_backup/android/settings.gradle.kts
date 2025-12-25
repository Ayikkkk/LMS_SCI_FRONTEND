pluginManagement {

    val props = java.util.Properties()
    file("local.properties").inputStream().use {
        props.load(it)
    }

    val flutterSdkPath = props.getProperty("flutter.sdk")
        ?: error("flutter.sdk not set in local.properties")

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    plugins {
        id("com.android.application") version "8.3.2"
        id("org.jetbrains.kotlin.android") version "1.9.22"
        id("dev.flutter.flutter-gradle-plugin") version "1.0.0"
    }
}

dependencyResolutionManagement {

    val props = java.util.Properties()
    file("local.properties").inputStream().use {
        props.load(it)
    }

    val flutterSdkPath = props.getProperty("flutter.sdk")
        ?: error("flutter.sdk not set in local.properties")

    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)

    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("$flutterSdkPath/bin/cache/artifacts/engine")
        }
    }
}

include(":app")

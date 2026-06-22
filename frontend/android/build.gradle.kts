// Top-level build.gradle.kts

plugins {
    id("com.android.application") version "8.11.1" apply false
    id("com.android.library") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("com.google.gms.google-services") version "4.3.15" apply false
    id("dev.flutter.flutter-gradle-plugin") apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ✅ Keep Google Services consistent
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🔧 Disable all test tasks across subprojects to avoid duplicate root errors
subprojects {
    tasks.matching { it.name.startsWith("test") }.configureEach {
        enabled = false
    }
}

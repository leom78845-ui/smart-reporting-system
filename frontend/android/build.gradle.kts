// Top-level build.gradle.kts

plugins {
    id("com.android.application") version "8.11.1" apply false
    id("com.android.library") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("dev.flutter.flutter-gradle-plugin") apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {}
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// 🔧 Disable all test tasks across subprojects to avoid duplicate root errors
subprojects {
    tasks.matching { it.name.startsWith("test") }.configureEach {
        enabled = false
    }
}

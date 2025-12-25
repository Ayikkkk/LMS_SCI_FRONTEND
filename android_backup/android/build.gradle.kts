import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()

        // 🔥 WAJIB untuk Flutter engine (arm64_v8a_debug)
        maven {
            url = uri("D:/flutter/bin/cache/artifacts/engine")
        }
    }
}

// ====== BUILD DIR (BOLEH, TIDAK MASALAH) ======
val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// ====== CLEAN ======
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

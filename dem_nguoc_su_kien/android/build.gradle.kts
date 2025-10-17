// Top-level build.gradle.kts file for Flutter Android project
// ===============================================

import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// Đặt thư mục build về chung cho tất cả module
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Đảm bảo project con :app được build trước
subprojects {
    project.evaluationDependsOn(":app")
}

// Lệnh dọn build
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

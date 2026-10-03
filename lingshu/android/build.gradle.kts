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

// 部分 Flutter 插件仍硬编码旧版 compileSdk（33/34），而依赖的 androidx 库要求 36，
// 在各子项目评估完成后统一提升到 36。
// 注意：必须先注册 afterEvaluate，再执行 evaluationDependsOn，否则触发
// "Cannot run Project.afterEvaluate when the project is already evaluated"。
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            if (ext is com.android.build.gradle.LibraryExtension) {
                if (ext.compileSdk == null || (ext.compileSdk ?: 0) < 36) {
                    ext.compileSdk = 36
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

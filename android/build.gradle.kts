allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Inject namespace if missing to support older plugins with AGP 8.0+ - AI-generated MiDaS fix
    afterEvaluate { // AI-generated MiDaS fix
        if (project.hasProperty("android")) { // AI-generated MiDaS fix
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension // AI-generated MiDaS fix
            if (android.namespace == null) { // AI-generated MiDaS fix
                android.namespace = "com.tflite.flutter.fix" // AI-generated MiDaS fix
            } // AI-generated MiDaS fix
        } // AI-generated MiDaS fix

        // Force JVM target compatibility to match Java version for every plugin - AI-generated MiDaS fix
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach { // AI-generated MiDaS fix
            val javaVersion = project.extensions.findByType<com.android.build.gradle.BaseExtension>()?.compileOptions?.targetCompatibility?.toString() // AI-generated MiDaS fix
            compilerOptions { // AI-generated MiDaS fix
                if (javaVersion != null) { // AI-generated MiDaS fix
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(javaVersion)) // AI-generated MiDaS fix
                } else { // AI-generated MiDaS fix
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11) // AI-generated MiDaS fix
                } // AI-generated MiDaS fix
            } // AI-generated MiDaS fix
        } // AI-generated MiDaS fix
    } // AI-generated MiDaS fix
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

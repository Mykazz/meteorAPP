// android/build.gradle.kts (project-level)

import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// keep your custom build dir mapping
val newBuildDir =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    // per-subproject build dir
    layout.buildDirectory.set(newBuildDir.dir(name))

    // ensure :app is evaluated first (your original intent)
    evaluationDependsOn(":app")

    // ---- Enforce Java 17 & Kotlin JVM 17 for all modules ----
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
        // Optional extra diagnostics:
        // options.compilerArgs.addAll(listOf("-Xlint:deprecation", "-Xlint:unchecked"))
        // To silence "obsolete options" warnings (not recommended):
        // options.compilerArgs.add("-Xlint:-options")
    }

    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions.jvmTarget = "17"
    }
}

// clean task (unchanged)
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

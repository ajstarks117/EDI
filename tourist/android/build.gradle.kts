buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

allprojects {
    buildscript {
        repositories {
            google()
            mavenCentral()
        }
        configurations.all {
            resolutionStrategy {
                force("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
            }
        }
    }
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
    val rootPath = rootProject.projectDir.absolutePath
    val projPath = project.projectDir.absolutePath
    val rootDrive = if (rootPath.contains(":")) rootPath.substringBefore(":") else ""
    val projDrive = if (projPath.contains(":")) projPath.substringBefore(":") else ""
    if (rootDrive.equals(projDrive, ignoreCase = true)) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureNamespace = Action<Project> {
        val project = this
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            val android = extensions.findByName("android")
            if (android != null) {
                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val namespace = getNamespace.invoke(android) as? String
                    if (namespace == null || namespace.isEmpty()) {
                        val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                        val pkgName = name.replace("-", "_").replace(":", "_")
                        setNamespace.invoke(android, "com.traveltrek.fallback.$pkgName")
                    }
                } catch (e: Exception) {
                    // Ignore
                }
                try {
                    val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                    val setSource = compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java)
                    val setTarget = compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java)
                    setSource.invoke(compileOptions, JavaVersion.VERSION_1_8)
                    setTarget.invoke(compileOptions, JavaVersion.VERSION_1_8)
                } catch (e: Exception) {
                    // Ignore
                }
            }
            project.tasks.whenTaskAdded {
                if (name.contains("process") && name.contains("Manifest")) {
                    doFirst {
                        val manifestFile = project.file("src/main/AndroidManifest.xml")
                        if (manifestFile.exists()) {
                            var content = manifestFile.readText(Charsets.UTF_8)
                            if (content.contains("package=")) {
                                content = content.replace(Regex("""package="[^"]*""""), "")
                                manifestFile.writeText(content, Charsets.UTF_8)
                                project.logger.lifecycle("Removed package attribute from $manifestFile")
                            }
                        }
                    }
                }
            }
            project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                kotlinOptions {
                    jvmTarget = "1.8"
                }
            }
        }
    }
    if (state.executed) {
        configureNamespace.execute(this)
    } else {
        afterEvaluate(configureNamespace)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

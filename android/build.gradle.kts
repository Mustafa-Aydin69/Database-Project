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

tasks.register("clean", Delete::class) {
    delete(rootProject.layout.buildDirectory)
}
// Ensure the Android SDK is located before any Android-specific configuration
if (!rootProject.extra.has("androidSdkRoot")) {
    val androidSdkRoot: String? = System.getenv("ANDROID_HOME")
        ?: System.getenv("ANDROID_SDK_ROOT")
        ?: rootProject.file("local.properties").takeIf { it.exists() }?.inputStream()?.use {
            java.util.Properties().apply { load(it) }.getProperty("sdk.dir")
        }

    if (androidSdkRoot.isNullOrBlank()) {
        throw GradleException(
            """
            Android SDK location not found. 
            Define a valid SDK location with an ANDROID_HOME environment variable 
            or by setting the sdk.dir path in your project's local.properties file.
            """.trimIndent()
        )
    }
    rootProject.extra["androidSdkRoot"] = file(androidSdkRoot).canonicalPath
}

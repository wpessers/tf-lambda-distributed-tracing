plugins {
    java
    id("com.gradleup.shadow") version "9.0.0-beta12" apply false
}

subprojects {
    apply(plugin = "java")

    repositories {
        mavenCentral()
    }

    java {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }
}

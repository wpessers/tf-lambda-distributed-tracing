plugins {
    id("com.gradleup.shadow")
}

dependencies {
    implementation("com.amazonaws:aws-lambda-java-core:1.2.3")
    implementation("com.amazonaws:aws-lambda-java-events:3.16.1")
    implementation("com.fasterxml.jackson.core:jackson-databind:2.18.3")
}

tasks.shadowJar {
    archiveClassifier.set("all")
}

tasks.register<Zip>("lambdaZip") {
    archiveFileName.set("launch.zip")
    destinationDirectory.set(layout.buildDirectory.dir("distributions"))

    into("lib") {
        from(tasks.shadowJar)
    }
    from("${rootProject.projectDir}/collector.yaml")
}

tasks.named("build") {
    dependsOn("lambdaZip")
}

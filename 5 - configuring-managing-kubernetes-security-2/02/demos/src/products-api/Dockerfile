FROM maven:3.9.11-eclipse-temurin-24-alpine AS builder

WORKDIR /build
# Copy only dependency files first (layer caching)
COPY pom-updated.xml pom.xml
RUN mvn dependency:go-offline

# Copy source and build
COPY src ./src
RUN mvn package -DskipTests

# Production runtime image
FROM eclipse-temurin:24-jre-alpine

# Upgrade libexpat to fix CVE
RUN apk update && apk upgrade libexpat && rm -rf /var/cache/apk/*

# Run as non-root user
RUN addgroup -g 1000 app && \
    adduser -D -u 1000 -G app app

WORKDIR /app

# Copy only the JAR file
COPY --from=builder --chown=app:app /build/target/products-api-0.1.0.jar app.jar

USER app
EXPOSE 8080

# Use JVM flags for container awareness
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]

ARG RELEASE_VERSION=0.1
ARG BUILD_NUMBER=999
ARG COMMIT_SHA=dockerfile

LABEL org.opencontainers.image.version=${RELEASE_VERSION}.${BUILD_NUMBER}
LABEL org.opencontainers.image.revision=${COMMIT_SHA}
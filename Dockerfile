FROM maven:3.8.7-openjdk-18-slim AS build
WORKDIR /app
COPY . .
RUN mvn package -DskipTests

FROM eclipse-temurin:21-jre-alpine AS run
ARG USER=devops
ENV HOME=/home/$USER

WORKDIR /run
COPY --from=build /app/target/*.jar demo.jar

RUN adduser -D -H -s /sbin/nologin $USER && \
    chown $USER:$USER /run/demo.jar

USER $USER
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --retries=2 --start-period=20s \
    CMD curl -f http://localhost:8080/ || exit 1

ENTRYPOINT ["java", "-jar", "/run/demo.jar"]
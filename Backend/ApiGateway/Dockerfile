FROM openjdk:latest
ARG JAR_FILE=target/GatewayDemo-0.0.1-SNAPSHOT.jar
COPY ${JAR_FILE} apigateway_app.jar
ENTRYPOINT ["java", "-jar", "./apigateway_app.jar"]
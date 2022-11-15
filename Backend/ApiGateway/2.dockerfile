FROM maven:3.5.4-jdk-8-alpine as maven

COPY ./pom.xml ./pom.xml
COPY ./src ./src
RUN mvn dependency:go-offline -B
RUN mvn package

#FROM openjdk:8u171-jre-alpine
##WORKDIR /adevguide
#COPY --from=maven target/SimpleJavaProject-*.jar ./SimpleJavaProject.jar
#CMD ["java", "-jar", "./SimpleJavaProject.jar"]

FROM openjdk:latest
ARG JAR_FILE=target/GatewayDemo-0.0.1-SNAPSHOT.jar

# use this when the build is being done by hand previous to this
#COPY ${JAR_FILE} app.jar

COPY --from=maven ${JAR_FILE} ./app.jar

ENTRYPOINT ["java", "-jar", "./app.jar"]
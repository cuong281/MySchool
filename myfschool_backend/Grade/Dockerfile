# Stage 1: build
# Start with a Maven image that includes Amazon Corretto JDK 17
FROM maven:3.9.8-amazoncorretto-17 AS build

# Copy source code and pom.xml file to /app folder
WORKDIR /app
COPY pom.xml .
COPY src ./src

# Build source code with maven
RUN mvn package -DskipTests

# Stage 2: create image
# Start with Amazon Corretto 17 Alpine (nhỏ gọn, bảo mật)
FROM amazoncorretto:17-alpine

# Set working folder to /app and copy compiled file from above step
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

# Expose port 8080
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

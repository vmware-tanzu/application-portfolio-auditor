# Build with: docker buildx build --platform "linux/amd64" -f "Dockerfile" -t bagger:1.0.1 .
# Execution with: 
FROM maven:3.9.6-eclipse-temurin-21 as build
RUN mkdir /app
COPY . /app
WORKDIR /app
RUN mvn clean package assembly:single -DskipTests
RUN jar xf target/bagger-1.0.1.jar
RUN jdeps --ignore-missing-deps -q  \
    --recursive  \
    --multi-release 21  \
    --print-module-deps  \
    --class-path 'BOOT-INF/lib/*'  \
    target/bagger-1.0.1.jar > deps.info
RUN jlink \
    --add-modules $(cat deps.info) \
    --strip-debug \
    --compress 2 \
    --no-header-files \
    --no-man-pages \
    --output /myjre

FROM debian:12.5-slim
ENV JAVA_HOME /user/java/jdk
ENV PATH $JAVA_HOME/bin:$PATH
ENV BAGGER_DB_TMP /app/bagger_tmp
RUN addgroup --gid 1234 javauser 
RUN useradd --uid 1234 -g javauser javauser
RUN mkdir -p /app $JAVA_HOME $BAGGER_DB_TMP
COPY --from=build /myjre $JAVA_HOME
COPY --from=build /app/target/bagger-1.0.1-jar-with-dependencies.jar /app/bagger.jar
WORKDIR /app
RUN chown -R javauser:javauser /app "${BAGGER_DB_TMP}"
USER javauser
ENTRYPOINT [ "java", "-Djava.io.tmpdir=/app/bagger_tmp", "-jar", "/app/bagger.jar" ]

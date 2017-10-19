FROM mikefaille/sbt-builder
MAINTAINER Michael Faille <michael@faille.io>

COPY ./code /tmp/play-scala-rest-api-example
RUN cd /tmp/play-scala-rest-api-example && \
    sbt dist


### MULTI-STEP BUILD ###
FROM openjdk:8u141-jre-slim
COPY --from=0 /tmp/play-scala-rest-api-example/target/universal/play-scala-rest-api-example-1.0-SNAPSHOT.zip /srv/
RUN cd /srv && \
    unzip play-scala-rest-api-example-1.0-SNAPSHOT.zip && \
    rm play-scala-rest-api-example-1.0-SNAPSHOT.zip

WORKDIR /srv/play-scala-rest-api-example-1.0-SNAPSHOT

EXPOSE 8080

CMD bin/play-scala-rest-api-example -Dplay.crypto.secret=testing

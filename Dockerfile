FROM mikefaille/sbt-builder as  sbt-example-package
MAINTAINER Michael Faille <michael@faille.io>

COPY ./code /tmp/play-scala-rest-api-example
RUN cd /tmp/play-scala-rest-api-example && \
    sbt dist


### MULTI-STEP BUILD ###
FROM openjdk:8u141-jre-slim
COPY --from=sbt-example-package  /tmp/play-scala-rest-api-example/target/universal/play-scala-rest-api-example-1.0-SNAPSHOT.zip  /srv/

RUN cd /srv && \
    unzip play-scala-rest-api-example-1.0-SNAPSHOT.zip && \
    rm play-scala-rest-api-example-1.0-SNAPSHOT.zip

WORKDIR /srv/play-scala-rest-api-example-1.0-SNAPSHOT

EXPOSE 9000

CMD bin/play-scala-rest-api-example -Dplay.crypto.secret=testing -Dhttp.address=0.0.0.0

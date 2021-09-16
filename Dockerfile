FROM amd64/adoptopenjdk:11-jre-openj9-bionic

MAINTAINER Subhabrata Sarkar

ARG ARCH=amd64
ARG JDK=adoptopenjdk:11-jre-openj9-bionic
ARG BUILD_DATE=31-Aug-21
ARG BUILD_VERSION
ARG BUILD_REF
ARG ALLURE_RELEASE=2.13.8
ARG ALLURE_CLI_URL=https://repo1.maven.org/maven2/io/qameta/allure/allure-commandline/2.13.8/allure-commandline-2.13.8.zip
ARG QEMU_ARCH=x86_64
ARG AUID=1000
ARG AGID=1000
###
ARG ENDPOINT
ENV GOOFYS_VERSION 0.23.1
ENV MOUNT_DIR /app/allure-docker-api/static/projects
ENV REGION ap-south-1
ENV BUCKET teleport-bucket
ENV STAT_CACHE_TTL 1m0s
ENV TYPE_CACHE_TTL 1m0s
ENV DIR_MODE 0700
ENV FILE_MODE 0600
ENV UID 0
ENV GID 0
###
ENV ROOT=/app
ENV ALLURE_HOME=/allure-$ALLURE_RELEASE
ENV ALLURE_HOME_SL=/allure
ENV PATH=$PATH:$ALLURE_HOME/bin
ENV ALLURE_RESOURCES=$ROOT/resources
ENV RESULTS_DIRECTORY=$ROOT/allure-result
ENV REPORT_DIRECTORY=$ROOT/allure-report
ENV RESULTS_HISTORY=$RESULTS_DIRECTORY/history
ENV REPORT_HISTORY=$REPORT_DIRECTORY/history
ENV ALLURE_VERSION=$ROOT/version
ENV EMAILABLE_REPORT_FILE_NAME='emailable-report-allure-docker-service.html'
ENV STATIC_CONTENT=$ROOT/allure-docker-api/static
ENV STATIC_CONTENT_PROJECTS=$STATIC_CONTENT/projects
ENV DEFAULT_PROJECT=default
ENV DEFAULT_PROJECT_ROOT=$STATIC_CONTENT_PROJECTS/$DEFAULT_PROJECT
ENV DEFAULT_PROJECT_RESULTS=$DEFAULT_PROJECT_ROOT/allure-results
ENV DEFAULT_PROJECT_REPORTS=$DEFAULT_PROJECT_ROOT/allure-reports
ENV EXECUTOR_FILENAME=executor.json

LABEL org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.docker.dockerfile="Dockerfile" \
    org.label-schema.license="MIT" \
    org.label-schema.name="Goofys-Allure Docker Service" \
    org.label-schema.version=${BUILD_VERSION} \
    org.label-schema.description="This is integrated docker image of Goofys (mount s3 Filesystem to any container or vm) and Allure Framework (a flexible lightweight multi-language test report tool) ." \
    org.label-schema.url="https://docs.qameta.io/allure/" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/covidboy/goofys-allure-docker-service" \
    org.label-schema.arch=${ARCH} \
    authors="Subhabrata Sarkar <subhabrataofficial2020@gmail.com>"

# QEMU - Quick Emulation
COPY allure-docker-service/qemu-x86_64-static /usr/bin/qemu-$QEMU_ARCH-static

RUN apt-get update && apt-get install -y --no-install-recommends gcc ca-certificates openssl musl-dev git fuse syslog-ng coreutils curl

RUN curl --fail -sSL -o /usr/local/bin/goofys https://github.com/kahing/goofys/releases/download/v${GOOFYS_VERSION}/goofys \
    && chmod +x /usr/local/bin/goofys
RUN curl -sSL -o /usr/local/bin/catfs https://github.com/kahing/catfs/releases/download/v0.8.0/catfs && chmod +x /usr/local/bin/catfs

RUN mkdir -p /app/allure-docker-api/static/projects

VOLUME /app/allure-docker-api/static/projects

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      tzdata \
      nano \
      python3 \
      python3-pip \
      python3-dev \
      unzip && \
    ln -s `which python3` /usr/bin/python && \
    pip3 install --upgrade pip && \
    pip install -Iv setuptools==47.1.1 wheel==0.34.2 waitress==1.4.4 && \
    pip install -Iv Flask==1.1.2 Flask-JWT-Extended==3.25.0 flask-swagger-ui==3.36.0 requests==2.23.0 && \
    curl https://repo1.maven.org/maven2/io/qameta/allure/allure-commandline/2.13.8/allure-commandline-2.13.8.zip -L -o /tmp/allure-commandline.zip && \
        unzip -q /tmp/allure-commandline.zip -d / && \
        apt-get remove -y unzip && \
        rm -rf /tmp/* && \
        rm -rf /var/lib/apt/lists/* && \
        chmod -R +x /allure-$ALLURE_RELEASE/bin && \
        mkdir -p /app

RUN groupadd --gid ${AGID} allure \
    && useradd --uid ${AUID} --gid allure --shell /bin/bash --create-home allure

RUN echo -n $(allure --version) > ${ALLURE_VERSION} && \
    echo "ALLURE_VERSION: "$(cat ${ALLURE_VERSION}) && \
    mkdir $ALLURE_HOME_SL && \
    ln -s $ALLURE_HOME/* $ALLURE_HOME_SL && \
    ln -s $STATIC_CONTENT_PROJECTS $ROOT/projects && \
    ln -s $DEFAULT_PROJECT_REPORTS $ROOT/default-reports

WORKDIR $ROOT
COPY --chown=allure:allure allure-docker-service/allure-docker-api $ROOT/allure-docker-api
COPY --chown=allure:allure allure-docker-service/allure-docker-scripts $ROOT/
RUN chmod +x $ROOT/*.sh && \
    mkdir $RESULTS_DIRECTORY && \
    mkdir -p $DEFAULT_PROJECT_REPORTS/latest && \
    ln -sf $RESULTS_DIRECTORY $DEFAULT_PROJECT_RESULTS && \
    ln -sf $DEFAULT_PROJECT_REPORTS/latest $REPORT_DIRECTORY && \
    allure generate -c -o /tmp/resources && \
    mkdir $ALLURE_RESOURCES && \
    cp /tmp/resources/app.js $ALLURE_RESOURCES && \
    cp /tmp/resources/styles.css $ALLURE_RESOURCES

RUN chown -R allure:allure $ROOT

VOLUME [ "$RESULTS_DIRECTORY" ]

ENV DEPRECATED_PORT=4040
ENV PORT=5050

EXPOSE $DEPRECATED_PORT
EXPOSE $PORT

COPY allure-docker-service/allure-docker-scripts/allure-run.sh /usr/bin/allure-run.sh
RUN chmod +x /usr/bin/allure-run.sh

ADD goofys/rootfs/ /

RUN chmod +x /run.sh

HEALTHCHECK --interval=10s --timeout=60s --retries=3 \
      CMD curl -f http://localhost:$PORT || exit 1

ENTRYPOINT ["/bin/bash", "-c" , "/run.sh & /usr/bin/allure-run.sh"]



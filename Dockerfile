## Setting image source variables
ARG IMAGE_SOURCE=node
ARG IMAGE_TAG=12-buster

## Setting base image
FROM ${IMAGE_SOURCE}:${IMAGE_TAG}

## Setting argument variables
ARG PYTHON_VERSION=3.8.2

ARG LC_ALL="en_US.UTF-8"

ARG NAME="spark-patterns"
ARG VERSION="0.0.0-dev"

ARG BUILD_DATE="$(git rev-parse --short HEAD)"
ARG VCS_REF="$(date -u +\"%Y-%m-%dT%H:%M:%SZ\")"

ARG APP_DIR="/usr/src/app"
ARG DATA_DIR="/usr/src/data"

## Setting metadata labels
LABEL "name"="$NAME"
LABEL "version"="$VERSION"

LABEL "com.github.repository"="https://github.com/AlexRogalskiy/spark-patterns"
LABEL "com.github.homepage"="https://github.com/AlexRogalskiy/spark-patterns"
LABEL "com.github.maintainer"="Sensiblemetrics, Inc. <hello@sensiblemetrics.io> (https://sensiblemetrics.io)"

LABEL "com.github.version"="$VERSION"
LABEL "com.github.build-date"="$BUILD_DATE"
LABEL "com.github.vcs-ref"="$VCS_REF"

LABEL "com.github.name"="$NAME"
LABEL "com.github.description"="Spark Design Patterns"

## Setting environment variables
ENV PYTHON_VERSION $PYTHON_VERSION

ENV APP_DIR=$APP_DIR \
    DATA_DIR=$DATA_DIR

# System-level base config
ENV TZ=UTC \
    LANGUAGE=en_US:en \
    LC_ALL=$LC_ALL \
    LANG=$LC_ALL \
    PYTHONIOENCODING=UTF-8 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

## Mounting volumes
VOLUME ["$APP_DIR"]

## Creating work directory
WORKDIR $APP_DIR

# (workaround) Install cookiecutter and mkdocs to avoid the need to run docker in docker
RUN cd /tmp && curl -O https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz && \
    tar -xvf Python-${PYTHON_VERSION}.tar.xz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations && \
    make -j 4 && \
    make altinstall

RUN apt update

RUN pip3.8 install --upgrade pip --quiet

RUN pip3.8 install mkdocs --no-cache-dir --quiet
RUN pip3.8 install mkdocs-material --no-cache-dir --quiet
RUN pip3.8 install markdown-include --no-cache-dir --quiet
RUN pip3.8 install mkdocs-techdocs-core --no-cache-dir --quiet
RUN pip3.8 install click-man --no-cache-dir --quiet
## click-man --target path/to/man/pages mkdocs

RUN pip3.8 install cookiecutter --no-cache-dir --quiet && \
    apt remove -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev libbz2-dev g++ python-pip python-dev && \
    rm -rf /var/cache/apt/* /tmp/Python-${PYTHON_VERSION}

COPY . ./

## Install dependencies
RUN npm install

## Run format checking & linting
RUN npm run all

## Expose port
EXPOSE 8000

## Running package bundle
ENTRYPOINT [ "sh", "-c", "mkdocs serve --verbose --dirtyreload" ]

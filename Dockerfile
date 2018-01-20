#########################
# multi stage Dockerfile
# 1. set up the build environment and build the expath-package
# 2. run the eXist-db
#########################
FROM openjdk:8-jdk as builder
LABEL maintainer="Peter Stadler"

ENV SMUFL_BUILD_HOME="/opt/smufl-build"

ARG XMLSH_URL="http://xmlsh-org-downloads.s3-website-us-east-1.amazonaws.com/archives%2Frelease-1_3_1%2Fxmlsh_1_3_1.zip"
ARG SAXON_URL="http://downloads.sourceforge.net/project/saxon/Saxon-HE/9.6/SaxonHE9-6-0-7J.zip" 
ARG IMAGE_SERVER="http://edirom.de/smufl-browser/"

ADD ${XMLSH_URL} /tmp/xmlsh.zip
ADD ${SAXON_URL} /tmp/saxon.zip

WORKDIR ${SMUFL_BUILD_HOME}

RUN apt-get update \
    && apt-get install -y --force-yes ant npm \
    && unzip /tmp/xmlsh.zip -d ${SMUFL_BUILD_HOME}/ \
    && unzip /tmp/saxon.zip -d ${SMUFL_BUILD_HOME}/saxon \
    && mv ${SMUFL_BUILD_HOME}/xmlsh* ${SMUFL_BUILD_HOME}/xmlsh \
    && chmod 755 /opt/smufl-build/xmlsh/unix/xmlsh \
    && npm install bower \
    && ln -s /usr/bin/nodejs /usr/local/bin/node

COPY . .

RUN addgroup smuflbuilder \
    && adduser smuflbuilder --ingroup smuflbuilder --disabled-password --system \
    && chown -R smuflbuilder:smuflbuilder ${SMUFL_BUILD_HOME}

USER smuflbuilder:smuflbuilder

RUN ant -lib saxon -Dimage.server=${IMAGE_SERVER} rebuild

#########################
# Now running the eXist-db
# and adding our freshly built xar-package
#########################
FROM stadlerpeter/existdb

COPY --from=builder /opt/smufl-build/build/*.xar ${EXIST_HOME}/autodeploy/

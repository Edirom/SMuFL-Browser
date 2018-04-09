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
ADD https://deb.nodesource.com/setup_8.x /tmp/nodejs_setup 

WORKDIR ${SMUFL_BUILD_HOME}

RUN apt-get update \
    && apt-get install -y --force-yes ant git \
    # installing nodejs
    && chmod 755 /tmp/nodejs_setup; sync \
    && /tmp/nodejs_setup \
    && apt-get install -y nodejs \
    # installing XMLShell and Saxon
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

# add SMuFL-browser specific settings 
# for a production ready environment with 
# SMuFL-browser as the root app.
# For more details about the options see  
# https://github.com/peterstadler/existdb-docker
ENV EXIST_ENV="production"
ENV EXIST_CONTEXT_PATH="/"
ENV EXIST_DEFAULT_APP_PATH="xmldb:exist:///db/apps/smufl-browser"

# simply copy our SMuFL-browser xar package
# to the eXist-db autodeploy folder
COPY --from=builder /opt/smufl-build/build/*.xar ${EXIST_HOME}/autodeploy/

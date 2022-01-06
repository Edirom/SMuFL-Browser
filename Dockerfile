#########################
# multi stage Dockerfile
# 1. set up the build environment and build the expath-package
# 2. run the eXist-db
#########################
FROM openjdk:17-jdk-bullseye as builder
LABEL maintainer="Peter Stadler"

ARG IMAGE_SERVER="https://smufl-browser.edirom.de/"
ENV SMUFL_BUILD_HOME="/opt/smufl-build"

WORKDIR ${SMUFL_BUILD_HOME}

RUN apt-get update \
    && apt-get install -y --no-install-recommends -o APT::Immediate-Configure=false ant libsaxonhe-java npm \
    && npm install -g yarn

COPY . .

RUN ant -lib /usr/share/java -Dimage.server=${IMAGE_SERVER} rebuild

#########################
# Now running the eXist-db
# and adding our freshly built xar-package
#########################
FROM stadlerpeter/existdb:5

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

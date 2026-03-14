FROM postgres:11.6-alpine

COPY ./init-products-db.sh /docker-entrypoint-initdb.d/

ARG RELEASE_VERSION=0.1
ARG BUILD_NUMBER=999
ARG COMMIT_SHA=dockerfile

LABEL org.opencontainers.image.version=${RELEASE_VERSION}.${BUILD_NUMBER}
LABEL org.opencontainers.image.revision=${COMMIT_SHA}
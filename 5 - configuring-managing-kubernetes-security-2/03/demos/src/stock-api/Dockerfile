FROM golang:1.23.4-alpine AS builder
ENV CGO_ENABLED=0

WORKDIR /go/stock-api
COPY ./src/go.mod .
COPY ./src/go.sum* .

COPY ./src .
RUN go mod tidy && go build -o /server

# app
FROM alpine:3.20

ENV POSTGRES_CONNECTION_STRING="host=products-db port=5432 user=postgres password=wired dbname=postgres sslmode=disable"
EXPOSE 8080

WORKDIR /app
COPY --from=builder /server .

CMD ["/app/server"]

ARG RELEASE_VERSION=0.1
ARG BUILD_NUMBER=999
ARG COMMIT_SHA=dockerfile

LABEL org.opencontainers.image.version=${RELEASE_VERSION}.${BUILD_NUMBER}
LABEL org.opencontainers.image.revision=${COMMIT_SHA}
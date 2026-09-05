FROM golang:1.27.1-trixie AS build

WORKDIR /usr/src

ADD go.mod go.sum ./
RUN go mod download && go mod verify

RUN go build github.com/jackc/tern/v2
RUN go build github.com/sqlc-dev/sqlc/cmd/sqlc

FROM debian:trixie-slim

COPY --from=build /usr/src/tern /usr/local/bin/
COPY --from=build /usr/src/sqlc /usr/local/bin/

WORKDIR /usr/src

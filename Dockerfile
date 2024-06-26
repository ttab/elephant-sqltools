FROM golang:1.22.2-bookworm AS build

WORKDIR /usr/src

RUN apt update && apt install build-essential -y

ADD go.mod go.sum ./
RUN go mod download && go mod verify

RUN go build github.com/jackc/tern/v2
RUN go build github.com/sqlc-dev/sqlc/cmd/sqlc

FROM debian:bookworm-slim

COPY --from=build /usr/src/tern /usr/local/bin/
COPY --from=build /usr/src/sqlc /usr/local/bin/

WORKDIR /usr/src

FROM --platform=$BUILDPLATFORM golang:1.27.2-trixie AS build

WORKDIR /usr/src

ADD go.mod go.sum ./
RUN go mod download && go mod verify

ARG TARGETOS TARGETARCH
ENV CGO_ENABLED=0

RUN GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -o /out/ tool

FROM debian:trixie-slim

COPY --from=build /out/ /usr/local/bin/

WORKDIR /usr/src

#!/bin/bash

set -e

cd ${0%/*}

# Retrieve dependencies
go get -d -v

# Run tests
go test -v

# Build binaries
CGO_ENABLED=0 go build -a --installsuffix cgo --ldflags="-s" -o micro-app main.go

# Package in Docker container
docker build -t registry.service.consul:5000/iverberk/micro-app .

docker push registry.service.consul:5000/iverberk/micro-app

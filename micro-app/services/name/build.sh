#!/bin/bash

set -e

cd ${0%/*}

go get

go test

CGO_ENABLED=0 go build -a --installsuffix cgo --ldflags="-s" -o name-service main.go

docker build -t registry.service.consul:5000/iverberk/name-service .

docker push registry.service.consul:5000/iverberk/name-service

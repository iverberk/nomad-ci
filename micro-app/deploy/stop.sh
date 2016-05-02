#!/bin/bash

set -e

if [ -z ${ENV+x} ]; then 
    echo "Please specify the ENV environment identifier"
    exit 1
fi

jobs=("micro-app" "name-service" "age-service" "redis")
for job in "${jobs[@]}"
do
    curl --silent -XDELETE --header "Content-Type: application/json" nomad.service.consul:4646/v1/job/$job-$ENV &> /dev/null
done

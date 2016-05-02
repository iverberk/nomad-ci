#!/bin/bash

set -e

cd "${0%/*}"

if [ -z ${ENV+x} ]; then 
    echo "Please specify the ENV environment identifier"
    exit 1
fi

jobs=("micro-app" "name-service" "age-service" "redis")
for job in "${jobs[@]}"
do
    sed "s/###ENV###/$ENV/g" jobs/$job.json.tmpl > jobs/$job.json
    curl --silent -XPUT -d @jobs/$job.json --header "Content-Type: application/json" nomad.service.consul:4646/v1/job/$job-$ENV &> /dev/null
done

sleep 20

echo -e "Environment url: " 

curl --silent -XGET consul.service.consul:8500/v1/catalog/service/micro-app-$ENV | jq -r '.[0] | .Address + ":" + (.ServicePort | tostring)'

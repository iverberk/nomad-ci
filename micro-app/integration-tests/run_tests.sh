#!/bin/bash

cd "${0%/*}"

# Start Firefox and Chrome browser nodes
echo "Starting Selenium browser nodes"
curl --silent -XPUT -d @jobs/selenium-chrome.json --header "Content-Type: application/json" nomad.service.consul:4646/v1/job/selenium-chrome &> /dev/null
curl --silent -XPUT -d @jobs/selenium-firefox.json --header "Content-Type: application/json" nomad.service.consul:4646/v1/job/selenium-firefox &> /dev/null

# Spin up integration environment
echo "Starting integration environment"
ENV=integration ../deploy/deploy.sh

# Install some additional npm libraries
npm install chai

# Set the base url for our micro-app from Consul
BASE_URL=$(curl --silent -XGET consul.service.consul:8500/v1/catalog/service/micro-app-integration | jq -r '.[0] | .Address + ":" + (.ServicePort | tostring) ')
sed -i "s/###BASE_URL###/$BASE_URL/g" wdio.conf.js

# Add some extra delay to allow image downloading
sleep 20

# Run tests
echo "Running integration tests"
wdio wdio.conf.js

# Tear down selenium browser nodes
echo "Stopping integration environment and browser nodes"
curl --silent -XDELETE --header "Content-Type: application/json" nomad.service.consul:4646/v1/job/selenium-firefox &> /dev/null
curl --silent -XDELETE --header "Content-Type: application/json" nomad.service.consul:4646/v1/job/selenium-chrome &> /dev/null

# Stop integration environent
ENV=integration ../deploy/stop.sh

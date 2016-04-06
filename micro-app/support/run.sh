#!/bin/sh

/consul-template -consul=consul.service.consul:8500 -once -template="/config.json.ctmpl:/config.json"

/micro-app

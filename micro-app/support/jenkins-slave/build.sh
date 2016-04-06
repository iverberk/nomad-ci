#!/bin/bash

vagrant ssh -c "cd /vagrant/micro-app/support/jenkins-slave && docker build -t registry.service.consul:5000/jenkins/slave-micro-app . && docker push registry.service.consul:5000/jenkins/slave-micro-app"

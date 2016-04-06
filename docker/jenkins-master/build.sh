#!/bin/bash

vagrant ssh -c "cd /vagrant/docker/jenkins-master && docker build -t registry.service.consul:5000/jenkins/master . && docker push registry.service.consul:5000/jenkins/master"

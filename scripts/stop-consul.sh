#!/bin/bash

vagrant ssh -c "/vagrant/nomad/bin/nomad stop consul"

# Remove Consul
vagrant ssh -c "sudo rm -rf /usr/bin/consul"

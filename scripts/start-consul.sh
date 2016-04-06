#!/bin/bash

# Make sure Consul is in the chroot
vagrant ssh -c "sudo cp -fr /vagrant/consul /usr/bin"

vagrant ssh -c "/vagrant/nomad/bin/nomad run /vagrant/nomad/jobs/consul.nomad"

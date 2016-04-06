#/bin/sh

vagrant ssh -c "sudo /vagrant/nomad/bin/nomad agent -dev -config /vagrant/nomad/config"

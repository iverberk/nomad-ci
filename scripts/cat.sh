#!/bin/bash

vagrant ssh -c "/vagrant/nomad/bin/nomad fs cat -job $1 alloc/logs/$2"

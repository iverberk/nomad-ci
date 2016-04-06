#!/bin/bash

vagrant ssh -c "/vagrant/nomad/bin/nomad fs ls -job $1 alloc/logs"

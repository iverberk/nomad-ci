# nomad-ci makefile

.PHONY: up

up :
	vagrant up

provision :
	vagrant provision

ssh :
	vagrant ssh

start_registry :
	scripts/start-registry.sh

stop_registry :
	scripts/stop-registry.sh

start_jenkins:
	docker/jenkins-master/build.sh
	scripts/start-jenkins-master.sh

stop_jenkins :
	scripts/stop-jenkins-master.sh

start_selenium :
	scripts/start-selenium-hub.sh

stop_selenium :
	scripts/stop-selenium-hub.sh

build_app :
	micro-app/support/jenkins-slave/build.sh

logs :
	scripts/logs.sh

status :
	scripts/status.sh

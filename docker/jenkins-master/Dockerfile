FROM jenkins:1.642.2

COPY home /usr/share/jenkins/ref/
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt

USER root

RUN apt-get update && apt-get install jq

USER jenkins

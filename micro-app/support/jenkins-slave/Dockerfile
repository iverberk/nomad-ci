FROM golang:1.6

ADD https://get.docker.com/builds/Linux/x86_64/docker-1.10.3 /usr/local/bin/docker

RUN apt-get update && \
    curl -sL https://deb.nodesource.com/setup_4.x | bash - && \
    apt-get install -y jq nodejs git openjdk-7-jre-headless && \
    npm install -g chai wdio-junit-reporter wdio-mocha-framework webdriverio && \
    chmod +x /usr/local/bin/docker

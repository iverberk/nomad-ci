FROM alpine:3.3

WORKDIR /

# consul-template
ADD https://releases.hashicorp.com/consul-template/0.14.0/consul-template_0.14.0_linux_amd64.zip consul-template.zip
RUN apk add --no-cache unzip && \
    unzip consul-template.zip && \
    rm consul-template.zip

# Application files
ADD micro-app micro-app
ADD config.json.ctmpl config.json.ctmpl
COPY ./support/run.sh run.sh

CMD ["/run.sh"]

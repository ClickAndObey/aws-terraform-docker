FROM hashicorp/terraform:1.0.8

WORKDIR /terraform

# Amazon Linux 2 will be upgrading the underlying Docker storage driver to use overlay2.
# The overlay2 driver does not support itself as a backing filesystem, meaning that Docker containers using overlay2
# cannot run inside another Docker container using overlay2, unless the VOLUME command is present.
VOLUME /var/lib/docker

RUN apk add zip
RUN apk add jq

# Need this in order to run aws commands outside of terraform.
RUN apk add --no-cache \
        python3 \
        py3-pip
RUN pip3 install --upgrade pip
RUN pip3 install awscli

COPY src/main/scripts /scripts

ENTRYPOINT ["/scripts/docker/run_terraform"]
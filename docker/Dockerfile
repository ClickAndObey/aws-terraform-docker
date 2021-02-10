FROM hashicorp/terraform:light

WORKDIR /terraform

COPY src/main/scripts /scripts

ENTRYPOINT ["/scripts/run_terraform"]
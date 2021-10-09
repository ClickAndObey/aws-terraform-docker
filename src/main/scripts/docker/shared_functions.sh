########################################################################################################################
### Shared Functions
###
### This file is meant to store functions that are used between the multiple scripts in this repo, as well as the
### multiple scripts that will be written as extensions to this container.
########################################################################################################################

configure_output() {
  if [ "${QUIET_MODE}" -eq 1  ]; then
    exec 6>&1 # saves stdout
    suppress_output
  fi
}

suppress_output() {
    if [ "${QUIET_MODE}" -eq 1  ]; then
        exec > /dev/null  # redirect stdout to /dev/null
    fi
}

unsuppress_output() {
    if [ "${QUIET_MODE}" -eq 1  ]; then
        exec 1>&6 # restore stdout
    fi
}

exec_cmd() {
  unsuppress_output
  $*
  suppress_output
}

export_aws_variables() {
  echo "Exporting AWS Variables..."
  export AWS_DEFAULT_REGION=${REGION}
  export AWS_PROFILE=${ENVIRONMENT}
  echo "Exported AWS Variables."
}

check_region() {
  if [ -z "${REGION}" ]; then
    echo "REGION must be provided."
    exit 1
  fi
}

check_environment() {
  if [ -z "${ENVIRONMENT}" ]; then
    echo "ENVIRONMENT must be provided."
    exit 1
  fi
}

check_service() {
  if [ -z "${SERVICE}" ]; then
    echo "SERVICE must be provided."
    exit 1
  fi
}

check_version() {
  if [ -z "${VERSION}" ]; then
    echo "VERSION must be provided."
    exit 1
  fi
}
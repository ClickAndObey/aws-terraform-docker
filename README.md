# AWS Terraform Docker

Project meant to create a simple docker image for use with creating infrastructure in AWS with terraform.

## Quick Start

1. Run `make`

## Usage

The usage of this project is to produce a docker image that can be used as the basis for AWS deployments via terraform.
The dockerization makes it much easier to control the environment used between machines, and the [run_terraform](src/main/scripts/local/run_terraform)
local script has the up to date and intended usage.


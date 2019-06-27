#!/bin/bash
# run once to create base ami 
packer build -var-file=./secrets/aws.json  ./packer_templates/base_ami/template.json
# run for creating production amis 
packer build -var-file=./secrets/aws.json  ./packer_templates/production_ami/template.json
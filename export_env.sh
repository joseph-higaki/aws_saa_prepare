#!/bin/bash
# EXECUTE: source /workspaces/aws_saa_prepare/export_env.sh
# Path to your .env file
ENV_FILE="/workspaces/aws_saa_prepare/.auth/terraform.env"

export TF_VAR_aws_access_key=$(awk -F= '/aws_access_key/{print $2}' $ENV_FILE)
export TF_VAR_aws_secret_key=$(awk -F= '/aws_secret_key/{print $2}' $ENV_FILE)
echo $TF_VAR_aws_access_key
echo $TF_VAR_aws_secret_key
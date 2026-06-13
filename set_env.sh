#!/bin/bash
# template/set_env.sh

GRADLE_ARGS="--info"
SERVICE_USER=""
DOMAIN="bitone.in"
PRINCIPAL="bitone"
LOCAL_PORT="80"
TOKEN=""

export SERVICE_USER DOMAIN PRINCIPAL LOCAL_PORT TOKEN GRADLE_ARGS

echo "Environment variables set:"
echo "  GRADLE_ARGS=$GRADLE_ARGS"


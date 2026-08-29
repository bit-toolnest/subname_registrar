#!/bin/bash
# source set_env.sh

# Defaults with override support
export GRADLE_ARGS="${GRADLE_ARGS:---info}"
export EXECUTION_TIMEOUT="${EXECUTION_TIMEOUT:-1800}"
export DOMAIN="${DOMAIN:-bitone.in}"

echo "Environment variables set:"
echo "  GRADLE_ARGS=$GRADLE_ARGS"
echo "  EXECUTION_TIMEOUT=$EXECUTION_TIMEOUT"




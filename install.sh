#!/usr/bin/env bash
echo "── FAAS Tunnel Multi-User Installer ──"

# Prompt only if not already set
: "${SERVICE_USER:=$(read -rp "Linux username to run service (SERVICE_USER): " tmp && echo "$tmp")}"
: "${DOMAIN:=$(read -rp "Domain (e.g. bitone.in): " tmp && echo "$tmp")}"
: "${PRINCIPAL:=$(read -rp "Principal (SSH login user): " tmp && echo "$tmp")}"
: "${LOCAL_PORT:=$(read -rp "Local port to expose: " tmp && echo "$tmp")}"
: "${TOKEN:=$(read -rsp "Token: " tmp && echo "$tmp")}"
echo

# Export to environment so nested gradlew sees them
export SERVICE_USER DOMAIN PRINCIPAL LOCAL_PORT TOKEN

./gradlew install

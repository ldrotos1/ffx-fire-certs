#!/bin/bash
echo "|-----------------------------------------------------------------------|"
echo "| This script will create the certificates for the ffx fire application |"
echo "|-----------------------------------------------------------------------|"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Creating root certificate"
winpty openssl req -x509 -sha256 -days 3650 -newkey rsa:4096 \
  -keyout "${SCRIPT_DIR}/certs/ffx-fire-root-CA.key" \
  -out "${SCRIPT_DIR}/certs/ffx-fire-root-CA.crt" \
  -subj "//SKIP=skip/CN=fairfaxfire.gov/emailAddress=admin@fairfaxfire.gov/C=US/ST=Virginia/L=Fairfax/O=Fairfax County/OU=Fire and Rescue" \
  -passin pass:'password' \
  -passout pass:'password'

echo "Root certificate created"

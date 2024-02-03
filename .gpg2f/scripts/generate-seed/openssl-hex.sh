#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Generate a random hex seed with OpenSSL
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... number of bytes (the generated hex string will be twice as long)
#-----------------------------------------------------------------------------------------------------------------------

if [[ $# -eq 0 ]]; then
    echo "ERROR: Missing arguments (syntax: .gpg2f/scripts/generate-seed/openssl-hex.sh [number-of-bytes])" >&2
    return 1
elif [[ $# -gt 1 ]]; then
    echo "ERROR: Too many arguments: $* (syntax: .gpg2f/scripts/generate-seed/openssl-hex.sh [number-of-bytes])" >&2
    return 1
elif ! openssl rand -hex "$1"; then
    echo "ERROR: \"openssl rand -hex $1\" returned an error" >&2
fi

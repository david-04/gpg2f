#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Generate a random hex seed with OpenSSL
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... number of bytes (the generated hex string will be twice as long)
#-----------------------------------------------------------------------------------------------------------------------

if [[ $# -ne 1 ]]; then
    echo "ERROR: Wrong arguments: openssl-hex.sh $* (syntax: openssl-hex.sh [number-of-bytes])" >&2
    return 1
elif ! openssl rand -hex "$1"; then
    echo "ERROR: \"openssl rand -hex $1\" returned an error"
fi

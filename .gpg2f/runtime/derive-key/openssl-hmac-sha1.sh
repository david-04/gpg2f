#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Perform a challenge-response using openssl with a GnuPG-encrypted secret
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... file with the GnuPG-encrypted challenge-response hex secret
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_challenge_response_openssl() {
    local ENCRYPTED_FILE="$1"
    if [[ $# -ne 1 ]]; then
        echo "ERROR: Wrong arguments: openssl-hmac-sha1.sh $* (syntax: openssl-hmac-sha1.sh [file-with-encrypted-secret])" >&2
        return 1
    elif [[ ! -f "${ENCRYPTED_FILE?}" ]]; then
        echo "ERROR: File ${ENCRYPTED_FILE?} does not exist" >&2
        return 1
    fi
    local SECRET
    # shellcheck disable=SC1091
    if ! SECRET=$(. .gpg2/runtime/gpg/decrypt "$1"); then
        echo "ERROR: Failed to decrypt \"$1\" (\". .gpg2/runtime/gpg/decrypt $1\" returned an error)" >&2
        return 1
    fi
    SECRET="${SECRET//$'\r'/}"
    SECRET="${SECRET//$'\n'/}"
    if [[ -z "${SECRET?}" ]]; then
        echo "ERROR: \"${FILE?}\" seems to be empty (or only contain whitespace)" >&2
        return 1
    fi
    local RESPONSE
    if ! RESPONSE=$(xxd -r -p | openssl dgst -sha1 -mac HMAC -macopt "hexkey:${SECRET?}" -hex | sed 's/.*= *//'); then
        echo "ERROR: xxd -r -p | openssl dgst -sha1 -mac HMAC -macopt hexkey:[secret] -hex | sed 's/.*= *//' returned an error" >&2
        return 1
    elif [[ -z "${RESPONSE?}" ]]; then
        echo "ERROR: xxd -r -p | openssl dgst -sha1 -mac HMAC -macopt hexkey:[secret] -hex | sed 's/.*= *//' returned an empty string" >&2
        return 1
    fi
    echo -n "${RESPONSE?}"
    return 0
}

# shellcheck disable=SC2317
if gpg2f_challenge_response_openssl "$@"; then
    unset gpg2f_challenge_response_openssl
    return 0 >/dev/null || exit 0
else
    unset gpg2f_challenge_response_openssl
    return 1 >/dev/null || exit 1
fi

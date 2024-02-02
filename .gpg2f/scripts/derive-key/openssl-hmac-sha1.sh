#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Perform a challenge-response using openssl with a GnuPG-encrypted secret
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... file with the GnuPG-encrypted challenge-response hex secret
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_challenge_response_openssl() {

    # extract and validate parameters
    local ENCRYPTED_FILE="$1"
    if [[ $# -eq 0 ]]; then
        echo "ERROR: Missing argument (syntax: .gpg2f/scripts/derive-key/openssl-hmac-sha1.sh [file-with-gpg-encrypted-secret])" >&2
        return 1
    elif [[ $# -gt 1 ]]; then
        echo "ERROR: Too many arguments: $* (syntax: .gpg2f/scripts/derive-key/openssl-hmac-sha1.sh [file-with-gpg-encrypted-secret])" >&2
        return 1
    elif [[ ! -f "${ENCRYPTED_FILE?}" ]]; then
        echo "ERROR: File ${ENCRYPTED_FILE?} does not exist" >&2
        return 1
    fi

    # decrypt the secret
    if [[ ! -f ".gpg2f/scripts/gpg/decrypt-file-to-stdout.sh" ]]; then
        echo "ERROR: $(pwd)/.gpg2f/scripts/gpg/decrypt-file-to-stdout.sh does not exist" >&2
        return 1
    fi
    local SECRET
    if ! SECRET=$(. .gpg2f/scripts/gpg/decrypt-file-to-stdout.sh "$1"); then
        echo "ERROR: Failed to decrypt $1" >&2
        return 1
    fi

    # normalize and validate the secret
    SECRET="${SECRET//$'\r'/}"
    SECRET="${SECRET//$'\n'/}"
    if [[ -z "${SECRET?}" ]]; then
        echo "ERROR: File ${FILE?} seems to be empty" >&2
        return 1
    fi

    # calculate the response
    local COMMAND=(xxd -r -p "|" openssl dgst -sha1 -mac HMAC -macopt "hexkey:${SECRET?}" -hex "|" sed 's/.*= *//')
    local RESPONSE
    if ! RESPONSE=$("${COMMAND[@]}"); then
        echo "ERROR: Command \"${COMMAND[*]?}\" returned an error" >&2
        return 1
    fi

    # normalize and validate the response
    RESPONSE="${RESPONSE//$'\r'/}"
    RESPONSE="${RESPONSE//$'\n'/}"
    if [[ -z "${RESPONSE?}" ]]; then
        echo "ERROR: Command \"${COMMAND[*]?}\" returned an empty string" >&2
        return 1
    fi

    # return the response
    echo -n "${RESPONSE?}"
}

# shellcheck disable=SC2317
if gpg2f_challenge_response_openssl "$@"; then
    unset gpg2f_challenge_response_openssl
    return 0 >/dev/null || exit 0
else
    unset gpg2f_challenge_response_openssl
    return 1 >/dev/null || exit 1
fi

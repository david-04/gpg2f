#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Perform a YubiKey challenge-response. The challenge is passed in via stdin
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... the YubiKey slot ("1" or "2")
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_yubikey_challenge_response() {

    # extract and validate parameters
    local SLOT="$1"
    if [[ $# -eq 0 ]]; then
        echo "ERROR: Missing arguments (syntax: .gpg2f/scripts/derive-key/yubikey-challenge-response.sh [slot])" >&2
        return 1
    elif [[ $# -gt 1 ]]; then
        echo "ERROR: Too many arguments: $* (syntax: .gpg2f/scripts/derive-key/yubikey-challenge-response.sh [slot])" >&2
        return 1
    elif [[ "${SLOT?}" != "1" && "${SLOT?}" != "2" ]]; then
        echo "ERROR: Unknown slot \"${SLOT?}\" passed to yubikey-challenge-response.sh (expected: 1 or 2)" >&2
        return 1
    fi

    # extract the challenge
    local CHALLENGE
    if ! CHALLENGE="$(cat)"; then
        echo "ERROR: Failed to read the challenge from stdin" >&2
        return 1
    fi

    # normalize the challenge
    CHALLENGE="${CHALLENGE//$'\r'/}"
    CHALLENGE="${CHALLENGE//$'\n'/}"
    if [[ -z "${CHALLENGE?}" ]]; then
        echo "ERROR: Failed to read the challenge from stdin" >&2
        return 1
    fi

    # obtain the response
    local RESPONSE
    local COMMAND=(ykman otp calculate "${SLOT?}" "${CHALLENGE?}")
    if ! RESPONSE=$("${COMMAND[@]}"); then
        echo "ERROR: Command \"${COMMAND[*]}\" returned an error" >&2
        return 1
    fi

    # normalize and validate the response
    local NORMALIZED_RESPONSE="${RESPONSE?}"
    NORMALIZED_RESPONSE="${NORMALIZED_RESPONSE//$'\r'/}"
    NORMALIZED_RESPONSE="${NORMALIZED_RESPONSE//$'\n'/ }"
    if [[ -z "${NORMALIZED_RESPONSE?}" ]]; then
        echo "ERROR: Command \"${COMMAND[*]}\" returned an empty result" >&2
        return 1
    fi

    # return the response
    echo -n "${NORMALIZED_RESPONSE}"
}

# shellcheck disable=SC2317
if gpg2f_yubikey_challenge_response "$@"; then
    unset gpg2f_yubikey_challenge_response
    return 0 >/dev/null || exit 0
else
    unset gpg2f_yubikey_challenge_response
    return 1 >/dev/null || exit 1
fi

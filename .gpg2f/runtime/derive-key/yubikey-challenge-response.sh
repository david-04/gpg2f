#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Perform a YubiKey challenge-response. The challenge is passed in via stdin
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... the YubiKey slot ("1" or "2")
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_challenge_response_yubikey() {
    local SLOT="$1"
    if [[ $# -ne 1 ]]; then
        echo "ERROR: Wrong arguments: yubikey-challenge-response.sh $* (syntax: yubikey-challenge-response.sh [slot])" >&2
        return 1
    elif [[ "${SLOT?}" != "1" && "${SLOT?}" != "2" ]]; then
        echo "ERROR: Unknown slot \"${SLOT?}\" passed to yubikey-challenge-response.sh (expected: 1 or 2)" >&2
        return 1
    fi
    local CHALLENGE
    CHALLENGE="$(cat)"
    if [[ $? -ne 0 || -z "${CHALLENGE?}" ]]; then
        echo "ERROR: yubikey-challenge-response failed to read the challenge from stdin" >&2
        return 1
    fi
    local RESPONSE
    if ! RESPONSE=$(ykman otp calculate "${SLOT?}" "${CHALLENGE?}"); then
        echo "ERROR: ykman otp calculate ${SLOT?} [challenge] returned an error" >&2
        return 1
    fi
    local NORMALIZED_RESPONSE
    IFS=$'\n' read -r NORMALIZED_RESPONSE <<<"${RESPONSE?}"
    NORMALIZED_RESPONSE="${NORMALIZED_RESPONSE//$'\r'/}"
    NORMALIZED_RESPONSE="${NORMALIZED_RESPONSE//$'\n'/ }"
    if [[ -z "${NORMALIZED_RESPONSE?}" ]]; then
        echo "ERROR: Failed to normalize the response (yielding an empty result)" >&2
        return 1
    fi
    echo -n "${NORMALIZED_RESPONSE}"
}

# shellcheck disable=SC2317
if gpg2f_challenge_response_yubikey "$@"; then
    unset gpg2f_challenge_response_yubikey
    return 0 >/dev/null || exit 0
else
    unset gpg2f_challenge_response_yubikey
    return 1 >/dev/null || exit 1
fi

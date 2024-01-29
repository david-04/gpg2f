#!/usr/bin/env bash
# shellcheck disable=SC2317

[[ "$1" == "decrypt.sh" ]] && shift

#-----------------------------------------------------------------------------------------------------------------------
# Verify that we're in the right directory and that all required files are present
#-----------------------------------------------------------------------------------------------------------------------

if [[ ! -f "./decrypt.sh" ]]; then
    echo "ERROR: decrypt.sh can only be invoked in its own directory (current working directory: $(pwd))" >&2
    return 1 2>/dev/null || exit 1
fi

if [[ ! -f "./settings.sh" ]]; then
    echo "ERROR: $(pwd)/settings.sh does not exist" >&2
    return 1 2>/dev/null || exit 1
fi

if [[ ! -f "./.gpg2f/runtime/gpg2f.sh" ]]; then
    echo "ERROR: $(pwd)/.gpg2f/runtime/gpg2f.sh does not exist" >&2
    return 1 2>/dev/null || exit 1
fi

#-----------------------------------------------------------------------------------------------------------------------
# Load the configuration and decrypt
#-----------------------------------------------------------------------------------------------------------------------

source ./settings.sh

if ! . .gpg2f/runtime/gpg2f.sh decrypt "${GPG2F_CFG_CHALLENGE_RESPONSE_DECRYPT?}" "${GPG2F_CFG_STATIC_PASSWORD_DECRYPT?}" "${GPG2F_CFG_GPG_COMMAND?}" "$@"; then
    unset GPG2F_CFG_CHALLENGE_RESPONSE_ENCRYPT GPG2F_CFG_CHALLENGE_RESPONSE_DECRYPT GPG2F_CFG_STATIC_PASSWORD_ENCRYPT GPG2F_CFG_STATIC_PASSWORD_DECRYPT GPG2F_CFG_GPG_COMMAND
    return 1 2>/dev/null || exit 1
else
    unset GPG2F_CFG_CHALLENGE_RESPONSE_ENCRYPT GPG2F_CFG_CHALLENGE_RESPONSE_DECRYPT GPG2F_CFG_STATIC_PASSWORD_ENCRYPT GPG2F_CFG_STATIC_PASSWORD_DECRYPT GPG2F_CFG_GPG_COMMAND
    return 0 2>/dev/null || exit 0
fi

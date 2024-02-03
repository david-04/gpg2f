#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Decrypt stdin to stdout
#-----------------------------------------------------------------------------------------------------------------------
# $* ... command line parameters to pass through to gpg
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_decrypt_stdin_to_stdout() {

    # decrypt stdin
    # shellcheck disable=SC2317
    if [[ ! -f .gpg2f/scripts/utils/gpg-base-command.sh ]]; then
        echo "ERROR: $(pwd)/.gpg2f/scripts/utils/gpg-base-command.sh does not exist" >&2
        return 1
    elif ! . .gpg2f/scripts/utils/gpg-base-command.sh encrypt-symmetrically --output - "$@"; then
        echo "ERROR: Failed to decrypt ${INPUT_FILE?}" >&2
        return 1
    fi

}

# shellcheck disable=SC2317
if gpg2f_decrypt_stdin_to_stdout "$@"; then
    unset gpg2f_decrypt_stdin_to_stdout
    return 0 2>/dev/null || exit 0
else
    unset gpg2f_decrypt_stdin_to_stdout
    return 1 2>/dev/null || exit 1
fi

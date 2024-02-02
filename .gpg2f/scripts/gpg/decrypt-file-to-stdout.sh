#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Decrypt a file to stdout
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... the file to decrypt
# $* ... additional command line parameters to pass through to gpg
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_decrypt_file_to_stdout() {

    # extract and validate parameters
    if [[ $# -eq 0 ]]; then
        echo "ERROR: Missing command line arguments. Syntax: .gnupg/scripts/gpg/decrypt-file-to-stdout.sh [file] [additional-gpg-options]" >&2
        return 1
    fi
    local INPUT_FILE="$1"
    shift
    if [[ ! -f "${INPUT_FILE?}" ]]; then
        echo "ERROR: \"${INPUT_FILE?}\" does not exist" >&2
        return 1
    fi

    # load configuration (if not already present)
    if [[ -z "${GPG2F_GPG_CMD[*]}" || ! "$(declare -p GPG2F_GPG_SYMMETRIC_ENCRYPTION_OPTIONS)" =~ "declare -a" || ! "$(declare -p GPG2F_GPG_ASYMMETRIC_ENCRYPTION_OPTIONS)" =~ "declare -a" || -z "${GPG2F_GPG_DECRYPTION_OPTIONS+x}" ]]; then
        if [[ ! -f ".gpg2f/scripts/utils/load-and-validate-config.sh" ]]; then
            echo "ERROR: $(pwd)/.gpg2f/scripts/utils/load-and-validate-config.sh does not exist" >&2
            return 1
        elif ! . .gpg2f/scripts/utils/load-and-validate-config.sh; then
            # shellcheck disable=SC2317
            return 1
        fi
    fi

    # assemle and execute the command
    # shellcheck disable=SC2317
    if [[ ! -f ".gpg2f/scripts/utils/gpg-base-command.sh" ]]; then
        echo "ERROR: $(pwd)/.gpg2f/scripts/utils/gpg-base-command.sh does not exist" >&2
        return 1
    elif ! . .gpg2f/scripts/utils/gpg-base-command.sh "${GPG2F_GPG_DECRYPTION_OPTIONS[@]}" "$@" --decrypt "${INPUT_FILE?}"; then
        echo "ERROR: Failed to decrypt ${INPUT_FILE?}" >&2
        return 1
    fi
}

# shellcheck disable=SC2317
if gpg2f_decrypt_file_to_stdout "$@"; then
    unset gpg2f_decrypt_file_to_stdout
    return 0 2>/dev/null || exit 0
else
    unset gpg2f_decrypt_file_to_stdout
    return 1 2>/dev/null || exit 1
fi

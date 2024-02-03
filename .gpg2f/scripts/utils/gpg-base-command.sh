#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Perform a GnuPG operation
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... operation ("encrypt-symmetrically", "encrypt-asymetrically" or ""decrypt")
# $* ... command line parameters to pass through to gpg
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_gpg_base_command() {

    # extract parameters
    if [[ $# -eq 0 ]]; then
        echo "ERROR: Missing arguments (syntax: .gpg2f/scripts/utils/gpg-base-command [encrypt-symmetrically|encrypt-asymmetrically|decrypt] [additional-gpg-options])" >&2
        return 1
    fi
    local OPERATION="$1"
    shift

    # load the configuration (if not already present)
    if [[ -z "${GPG2F_GPG_CMD[*]}" || ! "$(declare -p GPG2F_GPG_SYMMETRIC_ENCRYPTION_OPTIONS)" =~ "declare -a" || ! "$(declare -p GPG2F_GPG_ASYMMETRIC_ENCRYPTION_OPTIONS)" =~ "declare -a" || -z "${GPG2F_GPG_DECRYPTION_OPTIONS+x}" ]]; then
        if [[ ! -f ".gpg2f/scripts/utils/load-and-validate-config.sh" ]]; then
            echo "ERROR: $(pwd)/.gpg2f/scripts/utils/load-and-validate-config.sh does not exist" >&2
            return 1
        elif ! . .gpg2f/scripts/utils/load-and-validate-config.sh; then
            # shellcheck disable=SC2317
            return 1
        fi
    fi

    # assemble command: convert $HOME to a Cygwin path (Windows only)
    local COMMAND=()
    case "$(uname -s)" in
    CYGWIN*)
        if [[ -n "$HOME" ]]; then
            COMMAND=("${COMMAND[@]}" env "HOME=$(cygpath "${HOME?}")")
        fi
        ;;
    esac

    # assemble command: add base command
    COMMAND=("${COMMAND[@]}" "${GPG2F_GPG_CMD[@]}")

    # assemble command: append operation-specific options
    if [[ "${OPERATION?}" == "encrypt-symmetrically" ]]; then
        COMMAND=("${COMMAND[@]}" "${GPG2F_GPG_SYMMETRIC_ENCRYPTION_OPTIONS[@]}")
    elif [[ "${OPERATION?}" == "encrypt-asymmetrically" ]]; then
        COMMAND=("${COMMAND[@]}" "${GPG2F_GPG_ASYMMETRIC_ENCRYPTION_OPTIONS[@]}")
    elif [[ "${OPERATION?}" == "decrypt" ]]; then
        COMMAND=("${COMMAND[@]}" "${GPG2F_GPG_DECRYPTION_OPTIONS[@]}")
    else
        echo "ERROR: Unknown argument \"$OPERATION\" for .gpg2f/scripts/utils/gpg-base-command (expected: \"encrypt-symmetrically\", \"encrypt-asymmetrically\" or \"decrypt\")" >&2
        return 1
    fi

    # assemble command: append optional parameters passed to this script
    COMMAND=("${COMMAND[@]}" "$@")

    # execute the command
    if ! "${COMMAND[@]}"; then
        echo "ERROR: Command \"${COMMAND[*]}\" returned an error" >&2
        return 1
    fi
}

# shellcheck disable=SC2317
if gpg2f_gpg_base_command "$@"; then
    unset gpg2f_gpg_base_command
    return 0 2>/dev/null || exit 0
else
    unset gpg2f_gpg_base_command
    return 1 2>/dev/null || exit 1
fi

#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Perform a GnuPG operation
#-----------------------------------------------------------------------------------------------------------------------
# $* ... command line parameters to pass through to gpg
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_gpg_base_command() {

    # load the configuration (if not already present)
    if [[ -z "${GPG2F_GPG_CMD}" ]]; then
        if [[ ! -f ".gpg2f/scripts/utils/load-and-validate-config.sh" ]]; then
            echo "ERROR: $(pwd)/.gpg2f/scripts/utils/load-and-validate-config.sh does not exist" >&2
            return 1
        elif ! . .gpg2f/scripts/utils/load-and-validate-config.sh; then
            # shellcheck disable=SC2317
            return 1
        fi
    fi

    # Windows only: convert the HOME environment variable to a Cygwin path
    local SET_HOME_ENV_VARIABLE=()
    case "$(uname -s)" in
    CYGWIN*)
        if [[ -n "$HOME" ]]; then
            SET_HOME_ENV_VARIABLE=(env "HOME=$(cygpath "${HOME?}")")
        fi
        ;;
    esac

    # assemle and execute the command
    # shellcheck disable=SC2206
    local COMMAND=("${SET_HOME_ENV_VARIABLE[@]}" ${GPG2F_GPG_CMD?} "$@")
    if ! "${COMMAND[@]}"; then
        echo "ERROR: Command \"${COMMAND[*]})\" returned an error" >&2
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

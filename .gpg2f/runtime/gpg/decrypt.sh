--batch -qd

gpg2 --quiet --no-permission-warning --symmetric --batch

# encrypt
# echo abc | gpg2 --quiet --no-permission-warning --symmetric --armor
# decrypt
#  cat x.gpg | gpg2 --quiet --no-permission-warning -d

#-----------------------------------------------------------------------------------------------------------------------
# Decrypt stdin or a file to stdout
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... optional: the file to decrypt (instead of stdin)
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_run_decrypt_with_gpg2() {
    local INPUT_FILE="$1"
    if [[ $# -gt 1 ]]; then
        echo "ERROR: Wrong arguments: decrypt.sh $* (syntax: decrypt.sh [optional-file])" >&2
        return 1
    elif [[ -n "${INPUT_FILE?}" && ! -f "${INPUT_FILE?}" ]]; then
        echo "ERROR: \"${INPUT_FILE?}\" does not exist" >&2
        return 1
    fi
    local COMMAND_PREFIX=()
    case "$(uname -s)" in
    CYGWIN*)
        if [[ -n "$HOME" ]]; then
            COMMAND_PREFIX=(env HOME="$(cygpath "${HOME?}")")
        fi
        ;;
    esac
    # shellcheck disable=SC2086
    if ! "${COMMAND_PREFIX[@]}" ${GPG2F_GPG_CMD?} -d "$@"; then
        if [[ -n "${INPUT_FILE?}" ]]; then
            echo "ERROR: Failed to decrypt \"${INPUT_FILE?}\" (\"" "${COMMAND_PREFIX[@]}" "${GPG2F_GPG_CMD?} -d ${INPUT_FILE?}\" returned an error)" >&2
        else
            echo "ERROR: Failed to decrypt stdin (\"" "${COMMAND_PREFIX[@]}" "${GPG2F_GPG_CMD?} -d ${INPUT_FILE?}\" returned an error)" >&2
        fi
        return 1
    fi
}

# shellcheck disable=SC2317
if gpg2f_run_decrypt_with_gpg2 "$@"; then
    unset gpg2f_run_decrypt_with_gpg2
    return 0 >/dev/null || exit 0
else
    unset gpg2f_run_decrypt_with_gpg2
    return 1 >/dev/null || exit 1
fi

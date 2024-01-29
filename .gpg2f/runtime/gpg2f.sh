#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Display the program syntax
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_help() {
    echo "Syntax: gpg-sym2f.sh [encrypt|decrypt] [challenge-response] [static-password] [gpg-command] [file]"
    echo ""
    echo "[challenge-response] ... \"yubikey-slot-1\", \"yubikey-slot-2\" or a file with a GnuPG-encrypted hex secret"
    echo "[static-password] ...... file with a GnuPG-encrypted static password"
    echo "[gpg-command] .......... base command and options for GnuPG (e.g. gpg2 --batch --quiet)"
    echo "[touch-notification] ... command to to display a \"Touch the security key\" pop-up notification"
    echo "[file] ................. file to encrypt to or to decrypt from"
    echo
    echo "Setting either [challenge-response] or [static-password] to an empty string disables the respective feature."
    echo "Omitting [file] or setting it to an empty string encrypts to stdout or decrypts from stdin."
}

#-----------------------------------------------------------------------------------------------------------------------
# Main entry point
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... "encrypt" or "decrypt"
# $2 ... empty string, "yubikey-slot-1", "yubikey-slot-2" or a file with a GnuPG-encrypted challenge-response hex secret
# $3 ... empty string or a file with a GnuPG-encrypted static password
# $4 ... GnuPG base command and common options
# $5 ... command to to display a "Touch the security key" pop-up notification
# $6 ... optional: file to read from (when decrypting) or to write to (when encrypting)
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_main() {
    if [[ $# -eq 0 || $1 == "--help" || $1 == "-help" || $1 == "-h" ]]; then
        gpg2f_help >&2
        return 1
    fi
    if [[ $# -ne 4 && $# -ne 5 ]]; then
        echo -e "ERROR: Invalid parameters: $*\n" >&2
        gpg2f_help >&2
        return 1
    fi
    if [[ -z "$2" && -z "$3" ]]; then
        echo "ERROR: Invalid parameters: [challenge-response] and [static-password] are both emtpy (one must be set)" >&2
        gpg2f_help >&2
        return 1
    fi
    if [[ $1 == "encrypt" ]]; then
        shift
        gpg2f_encrypt "$@"
        return $?
    elif [[ $1 == "decrypt" ]]; then
        shift
        gpg2f_decrypt "$@"
        return $?
    else
        echo "ERROR: Invalid parameters: Unknown operation \"$1\" (allowed values: \"encrypt\" or \"decrypt\")" >&2
        gpg2f_help >&2
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Encrypt from stdin
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... empty string, "yubikey-slot-1", "yubikey-slot-2" or a file with a GnuPG-encrypted challenge-response hex secret
# $2 ... empty string or a file with a GnuPG-encrypted static password
# $3 ... GnuPG base command and common options
# $4 ... command to to display a "Touch the security key" pop-up notification
# $5 ... optional: file to read from (when decrypting) or to write to (when encrypting)
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_encrypt() {
    local CHALLENGE=""
    local RESPONSE=""
    if [[ -n "$1" ]]; then
        CHALLENGE=$(gpg2f_generate_random_challenge) || return 1
        RESPONSE=$(gpg2f_challenge_response "$3" "$4" "$1" "${CHALLENGE}") || return 1
    fi
    local STATIC_PASSWORD=""
    if [[ -n "$2" ]]; then
        STATIC_PASSWORD=$(gpg2f_get_static_password "$3" "$2") || return 1
    fi
    local PASSWORD="${RESPONSE?}${STATIC_PASSWORD?}"
    if [[ -z "$PASSWORD" ]]; then
        echo "ERROR: The encryption password is empty" >&2
        return 1
    fi
    if [[ -n "$5" ]]; then
        mkdir -p "$(dirname "$5")"
    fi
    if [[ -n "${CHALLENGE}" ]]; then
        if [[ -n "$5" ]]; then
            echo "${CHALLENGE?}" >"$5.tmp"
        else
            echo "${CHALLENGE?}"
        fi
    else
        echo -n "" >"$5.tmp"
    fi
    local EXIT_CODE
    if [[ -n "$5" ]]; then
        gpg2f_run_gpg2 "$3" --armor --symmetric --batch --passphrase-fd 3 --output - 3<<<"${PASSWORD?}" >>"$5.tmp"
        EXIT_CODE=$?
    else
        gpg2f_run_gpg2 "$3" --armor --symmetric --batch --passphrase-fd 3 --output - 3<<<"${PASSWORD?}"
        EXIT_CODE=$?
    fi
    if [[ ${EXIT_CODE} -ne 0 ]]; then
        echo "ERROR: Failed to encrypt stdin with gpg2" >&2
        if [[ -n "$5" ]]; then
            rm -f "$5.tmp"
        fi
        return 1
    fi

    if [[ -n "$5" ]]; then
        if ! mv -f "$5.tmp" "$5"; then
            echo "ERROR: Failed to overwrite \"$5\" with \"$5.tmp\"" >&2
            rm -f "$5.tmp"
            return 1
        elif [[ ! -f "$5" ]]; then
            echo "ERROR: Failed to overwrite \"$5\"" >&2
            rm -f "$5.tmp"
            return 1
        fi
    fi
    return 0
}

#-----------------------------------------------------------------------------------------------------------------------
# Decrypt a file to stdout
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... empty string, "yubikey-slot-1", "yubikey-slot-2" or a file with a GnuPG-encrypted challenge-response hex secret
# $2 ... empty string or a file with a GnuPG-encrypted static password
# $3 ... GnuPG base command and common options
# $4 ... command to to display a "Touch the security key" pop-up notification
# $5 ... optional: file to read from (when decrypting) or to write to (when encrypting)
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_decrypt() {
    local FILE_CONTENT
    if [[ -z "$5" ]]; then
        FILE_CONTENT="$(cat)"
    elif [[ ! -f "$5" ]]; then
        echo "ERROR: File \"$5\" does not exist" >&2
        return 1
    else
        FILE_CONTENT="$(cat "$5")"
    fi
    local CHALLENGE=""
    local RESPONSE=""
    if [[ -n "$1" ]]; then
        CHALLENGE=$(echo -en "${FILE_CONTENT?}" | head -n 1)
        if [[ $? -ne 0 || -z "${CHALLENGE?}" ]]; then
            echo "ERROR: Failed to extract the challenge from \"$5\"" >&2
            return 1
        fi
        RESPONSE=$(gpg2f_challenge_response "$3" "$4" "$1" "${CHALLENGE}") || return 1
    fi
    local STATIC_PASSWORD=""
    if [[ -n "$2" ]]; then
        STATIC_PASSWORD=$(gpg2f_get_static_password "$3" "$2") || return 1
    fi
    local PASSWORD="${RESPONSE?}${STATIC_PASSWORD?}"
    if [[ -z "$PASSWORD" ]]; then
        echo "ERROR: The encryption password is empty" >&2
        return 1
    fi
    local TAIL_OPTION=
    if [[ -z "${CHALLENGE?}" ]]; then
        TAIL_OPTION=+1
    else
        TAIL_OPTION=+2
    fi
    local DECRYPTED_CONTENT
    if ! DECRYPTED_CONTENT=$(echo -en "${FILE_CONTENT?}" | tail -n "${TAIL_OPTION?}" | gpg2f_run_gpg2 "$3" --decrypt --batch --passphrase-fd 3 --output - 3<<<"${PASSWORD?}"); then
        echo "ERROR: Failed to decrypt \"$5\" with gpg2" >&2
        return 1
    fi
    echo -en "${DECRYPTED_CONTENT?}"
    return 0
}

#-----------------------------------------------------------------------------------------------------------------------
# Generate a random hex challenge with openssl
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_generate_random_challenge() {
    local CHALLENGE
    CHALLENGE=$(openssl rand -hex 63)
    if [[ $? -eq 0 && ${#CHALLENGE} -eq 126 ]]; then
        echo -en "${CHALLENGE?}"
        return 0
    else
        echo "ERROR: Failed to generate a random challenge via \"openssl rand -hex 64\"" >&2
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Calculate the response for a challenge
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... GnuPG base command and common options
# $2 ... command to to display a "Touch the security key" pop-up notification
# $3 ... "yubikey-slot-1", "yubikey-slot-2" or a file with a GnuPG-encrypted challenge-response hex secret
# $4 ... challenge
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_challenge_response() {
    if [[ "$3" == "yubikey-slot-1" ]]; then
        gpg2f_challenge_response_yubikey "$2" 1 "$4"
        return $?
    elif [[ "$3" == "yubikey-slot-2" ]]; then
        gpg2f_challenge_response_yubikey "$2" 2 "$4"
        return $?
    else
        gpg2f_challenge_response_openssl "$@"
        return $?
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Perform a challenge-response using a Yubikey
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... command to to display a "Touch the security key" pop-up notification
# $2 ... yubikey slot (1 or 2)
# $3 ... challenge
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_challenge_response_yubikey() {
    local RESPONSE NOTIFICATION_COMMAND_PID EXIT_CODE
    if [[ -n "$1" ]]; then
        $1 "Touch the security key (challenge-response)" &
        NOTIFICATION_COMMAND_PID=$!
    fi
    RESPONSE="$(ykman otp calculate "$2" "$3" | head -n 1 | sed 's/[\r\n]//g')"
    EXIT_CODE=$?
    if [[ -n "${NOTIFICATION_COMMAND_PID?}" ]]; then
        kill "${NOTIFICATION_COMMAND_PID?}" >/dev/null 2>&1
    fi
    if [[ ${EXIT_CODE?} -eq 0 && -n "${RESPONSE}" ]]; then
        echo -n "${RESPONSE?}"
        return 0
    else
        echo "ERROR: Failed to run \"ykman otp calculate $2 [challenge]\"" >&2
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Perform a challenge-response using openssl with a GnuPG-encrypted secret
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... GnuPG base command and common options
# $2 ... file with a GnuPG-encrypted challenge-response hex secret
# $3 ... challenge
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_challenge_response_openssl() {
    if [[ ! -f "$2" ]]; then
        echo "ERROR: File \"$2\" does not exist" >&2
        return 1
    fi
    local SECRET
    SECRET=$(gpg2f_run_gpg2 "$1" --batch -qd "$2")
    if [[ $? -ne 0 || -z "${SECRET?}" ]]; then
        echo "ERROR: Failed to retrive the secret from \"$2\"" >&2
        return 1
    fi
    local RESPONSE
    RESPONSE=$(echo -n "$3" | xxd -r -p | openssl dgst -sha1 -mac HMAC -macopt "hexkey:${SECRET?}" -hex | sed 's/.*= *//')
    if [[ $? -ne 0 || -z "${SECRET?}" ]]; then
        echo "ERROR: Failed to run: echo -n \"[challenge]\" | xxd -r -p | openssl dgst -sha1 -mac HMAC -macopt \"hexkey:[secret]\" -hex | sed 's/.*= *//'" >&2
        return 1
    fi
    echo -n "${RESPONSE?}"
    return 0
}

#-----------------------------------------------------------------------------------------------------------------------
# Decrypt the static password
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... GnuPG base command and common options
# $2 ... GnuPG-encrypted file with a static password
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_get_static_password() {
    if [[ -f "$2" ]]; then
        local FILE_CONTENT
        if ! FILE_CONTENT=$(gpg2f_run_gpg2 "$1" --batch -qd "$2"); then
            echo "ERROR: Failed to decrypt \"$2\" with gpg2" 1>&2
            return 1
        fi
        local TRIMMED_CONTENT
        TRIMMED_CONTENT=$(echo -en "${FILE_CONTENT}" | sed 's/^[ \t]+//;s/[ \t\r]*$//' | grep -v '^$')
        if [[ $? -ne 0 || -z "${TRIMMED_CONTENT?}" ]]; then
            echo "ERROR: Failed to decrypt \"$2\" - the file is empty or only contains whitespace" >&2
            return 1
        elif [[ $(echo -en "${TRIMMED_CONTENT?}" | wc -l) -ge 2 ]]; then
            echo "ERROR: Failed to decrypt the static password - \"$2\" contains multiple lines of text" >&2
            return 1
        fi
        local PASSWORD
        PASSWORD=$(echo -en "${TRIMMED_CONTENT}" | head -n 1)
        if [[ $? -ne 0 || -z "${PASSWORD?}" ]]; then
            echo "ERROR: Failed to decrypt the static password - \"$2\" is empty or only contains whitespace" >&2
            return 1
        fi
        echo -ne "${PASSWORD?}"
        return 0
    else
        echo "ERROR: Failed to decrypt the static password - \"$2\" is not a file" >&2
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Run GnuPG
#-----------------------------------------------------------------------------------------------------------------------
# $@ ... GnuPG command with options
# $* ... arguments to pass on to GnuPG
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_run_gpg2() {
    local GPG_COMMAND="$1"
    shift
    case "$(uname -s)" in
    CYGWIN*)
        if [[ -n "$HOME" ]]; then
            # shellcheck disable=SC2086
            env HOME="$(cygpath "${HOME?}")" ${GPG_COMMAND?} "$@"
            return $?
        fi
        ;;
    esac
    ${GPG_COMMAND?} "$@"
    return $?
}

#-----------------------------------------------------------------------------------------------------------------------
# Unset all functions from this file (in case we're source'd)
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_unset() {
    local FUNCTIONS=(
        gpg2f_help
        gpg2f_main
        gpg2f_encrypt
        gpg2f_decrypt
        gpg2f_generate_random_challenge
        gpg2f_challenge_response
        gpg2f_challenge_response_yubikey
        gpg2f_challenge_response_openssl
        gpg2f_get_static_password
        gpg2f_run_gpg2
        gpg2f_unset
    )
    unset "${FUNCTIONS?}"
}

#-----------------------------------------------------------------------------------------------------------------------
# Run the application
#-----------------------------------------------------------------------------------------------------------------------

# shellcheck disable=SC2317
if gpg2f_main "$@"; then
    gpg2f_unset
    return 0 2>/dev/null || exit 0
else
    gpg2f_unset
    gpg2f_unset
    return 1 2>/dev/null || exit 1
fi

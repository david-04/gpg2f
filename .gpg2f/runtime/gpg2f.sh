#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Load the configuration
#-----------------------------------------------------------------------------------------------------------------------

if [[ -f "./settings.sh" ]]; then
    # shellcheck disable=SC1091
    . "./settings.sh"
elif [[ -f "./.gpg2f/examples/settings.example.sh" ]]; then
    # shellcheck disable=SC1091
    . "./.gpg2f/examples/settings.example.sh"
else
    echo "ERROR: Neither $(pwd)/settings.sh nor $(pwd)/.gpg2f/examples.settings.example.sh exists" >&2
    # shellcheck disable=SC2317
    return 1 2>/dev/null || exit 1
fi

#-----------------------------------------------------------------------------------------------------------------------
# Run the application and unset all functions and variables. All parameters are passed through to gpg2f_main.
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_run_and_unset() {
    local FUNCTIONS_TO_UNSET=(
        gpg2f_run_and_unset
        gpg2f_main
        gpg2f_display_syntax_help
        gpg2f_display_version_and_copyright
        gpg2f_validate_configuration
        gpg2f_encrypt
        gpg2f_decrypt
        gpg2f_generate_random_seed
        gpg2f_normalize_seed
        gpg2f_derive_encryption_key
        gpg2f_validate_and_hash_derived_key
        gpg2f_run_gpg
    )
    local CONFIG_VARIABLES_TO_UNSET=(
        GPG2F_GPG_CMD
        GPG2F_DECRYPTION_KEY_DERIVATION_CMD
        GPG2F_ENCRYPTION_KEY_DERIVATION_CMD
        GPG2F_MIN_DERIVED_KEY_LENGTH
        GPG2F_GENERATED_SEED_CMD
        GPG2F_GENERATED_SEED_EXPECTED_LENGTH
        GPG2F_HASH_DERIVED_KEY_CMD
        GPG2F_NOTIFICATION_CMD
        GPG2F_DEFAULT_NOTIFICATION_OPTIONS
    )
    local EXIT_CODE
    gpg2f_main "$@"
    EXIT_CODE=$?
    unset "${FUNCTIONS_TO_UNSET?}" "${CONFIG_VARIABLES_TO_UNSET?}"
    unset CONFIG_VARIABLES_TO_UNSET FUNCTIONS_TO_UNSET
    return ${EXIT_CODE?}
}

#-----------------------------------------------------------------------------------------------------------------------
# Main entry point
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... "encrypt" or "decrypt"
# $2 ... optional: file to read from (when decrypting) or to write to (when encrypting)
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_main() {
    local OPERATION=""
    if [[ "$1" == "encrypt" || "$1" == "decrypt" ]]; then
        OPERATION="$1"
        shift
    fi
    if [[ "$1" == "--help" || "$1" == "-help" || "$1" == "-h" ]]; then
        gpg2f_display_syntax_help
        return 0
    elif [[ "$1" == "--version" || "$1" == "-version" || "$1" == "-v" ]]; then
        gpg2f_display_version_and_copyright
        return 0
    fi
    if [[ 1 -lt $# || -z "${OPERATION?}" ]]; then
        if [[ -n "${OPERATION?}" ]]; then
            echo "ERROR: Invalid parameters: gpg2f.sh ${OPERATION?} $*" >&2
        else
            echo "ERROR: Invalid parameters: gpg2f.sh $*" >&2
        fi
        echo "" >&2
        gpg2f_display_syntax_help >&2
        return 1
    fi
    if ! gpg2f_validate_configuration >&2; then
        return 1
    fi
    if ! "gpg2f_${OPERATION?}" "$@"; then
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Display syntax help
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_display_syntax_help() {
    echo "gpg2f - Symmetric multifactor-encryption with GnuPG"
    echo ""
    echo "Syntax: encrypt.sh [file]"
    echo "    or: decrypt.sh [file]"
    echo ""
    echo "Encrypt stdin to the given [file] or decrypt the given [file] to stdout."
    echo "If [file] is not given, encrypt to stdout or decrypt from stdin."
    echo ""
    echo "Full documentation: https://github.com/david-04/gpg2f/blob/main/README.md"
}

#-----------------------------------------------------------------------------------------------------------------------
# Display version information
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_display_version_and_copyright() {
    echo "gpg2f 0.0.0"                      # version
    echo "Copyright (c) 2024 David Hofmann" # copyright
    echo "License: MIT <https://opensource.org/licenses/MIT>"
}

#-----------------------------------------------------------------------------------------------------------------------
# Validate the configuration
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_validate_configuration() {
    local EXIT_CODE=0
    if [[ -z "${GPG2F_GPG_CMD}" ]]; then
        echo "ERROR: GPG2F_GPG_CMD is not set"
        EXIT_CODE=1
    fi
    if [[ -z "${GPG2F_GENERATED_SEED_CMD}" ]]; then
        echo "ERROR: GPG2F_GENERATED_SEED_CMD is not set"
        EXIT_CODE=1
    fi
    if [[ -z "${GPG2F_GENERATED_SEED_EXPECTED_LENGTH}" ]]; then
        echo "ERROR: GPG2F_GENERATED_SEED_EXPECTED_LENGTH is not set"
        EXIT_CODE=1
    fi
    if [[ -z "${GPG2F_DECRYPTION_KEY_DERIVATION_CMD}" ]]; then
        echo "ERROR: GPG2F_DECRYPTION_KEY_DERIVATION_CMD is not set"
        EXIT_CODE=1
    fi
    if [[ "${#GPG2F_DECRYPTION_KEY_DERIVATION_CMD[@]}" -eq 0 ]]; then
        echo "ERROR: GPG2F_DECRYPTION_KEY_DERIVATION_CMD is not set"
        EXIT_CODE=1
    fi
    if [[ -z "${GPG2F_ENCRYPTION_KEY_DERIVATION_CMD}" ]]; then
        echo "ERROR: GPG2F_ENCRYPTION_KEY_DERIVATION_CMD is not set"
        EXIT_CODE=1
    fi
    if [[ "${#GPG2F_ENCRYPTION_KEY_DERIVATION_CMD[@]}" -eq 0 ]]; then
        echo "ERROR: GPG2F_ENCRYPTION_KEY_DERIVATION_CMD is not set"
        EXIT_CODE=1
    fi
    if [[ -z "${GPG2F_MIN_DERIVED_KEY_LENGTH?}" ]]; then
        echo "ERROR: GPG2F_MIN_DERIVED_KEY_LENGTH is not set" >&2
        EXIT_CODE=1
    elif [[ ${GPG2F_MIN_DERIVED_KEY_LENGTH?} -lt 10 ]]; then
        echo "ERROR: GPG2F_MIN_DERIVED_KEY_LENGTH must be at least 10 (current value: ${GPG2F_MIN_DERIVED_KEY_LENGTH?})" >&2
        EXIT_CODE=1
    fi
    if [[ -z "${GPG2F_HASH_DERIVED_KEY_CMD}" ]]; then
        echo "ERROR: GPG2F_HASH_DERIVED_KEY_CMD is not set"
        EXIT_CODE=1
    fi
    if [[ -z "${GPG2F_NOTIFICATION_CMD}" ]]; then
        echo "ERROR: GPG2F_NOTIFICATION_CMD is not set"
        EXIT_CODE=1
    fi
    if [[ -z "${GPG2F_DEFAULT_NOTIFICATION_OPTIONS+x}" ]]; then
        echo "ERROR: GPG2F_DEFAULT_NOTIFICATION_OPTIONS is not set"
        EXIT_CODE=1
    fi
    return "${EXIT_CODE?}"
}

#-----------------------------------------------------------------------------------------------------------------------
# Encrypt from stdin
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... optional: file to encrypt to (instead of stdout)
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_encrypt() {
    local OUTPUT_FILE="$1"
    local SEED
    if ! SEED="$(gpg2f_generate_random_seed)"; then
        return 1
    fi
    local ENCRYPTION_KEY
    if ! SEED=$(gpg2f_normalize_seed "${SEED?}"); then
        return 1
    fi
    if ! ENCRYPTION_KEY=$(gpg2f_derive_encryption_key "${SEED?}" "GPG2F_ENCRYPTION_KEY_DERIVATION_CMD" "${GPG2F_ENCRYPTION_KEY_DERIVATION_CMD[@]}"); then
        return 1
    fi
    if [[ -n "${OUTPUT_FILE}" ]]; then
        mkdir -p "$(dirname "${OUTPUT_FILE?}")"
        exec >"${OUTPUT_FILE?}.tmp"
    fi
    echo "$SEED"
    if ! gpg2f_run_gpg "enrypt" --armor --symmetric --batch --passphrase-fd 3 --output - 3<<<"${ENCRYPTION_KEY?}"; then
        if [[ -n "${OUTPUT_FILE}" ]]; then
            exec >&1
            rm -f "${OUTPUT_FILE?}.tmp" 2>/dev/null
        fi
        return 1
    fi
    if [[ -n "${OUTPUT_FILE}" ]]; then
        exec >&1
        if ! mv -f "${OUTPUT_FILE?}.tmp" "${OUTPUT_FILE?}"; then
            echo "ERROR: Failed to rename \"${OUTPUT_FILE?}.tmp\" to \"${OUTPUT_FILE?}\"" >&2
            rm -f "${OUTPUT_FILE?}.tmp.tmp" 2>/dev/null
            return 1
        fi
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Decrypt to stdout
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... optional: file to decrypt from (instead of stdin)
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_decrypt() {
    if [[ -n "$1" ]]; then
        exec <"$1"
    fi
    local SEED
    IFS=$'\n' read -r SEED
    if ! SEED=$(gpg2f_normalize_seed "${SEED?}"); then
        exec <&0
        return 1
    fi
    if ! ENCRYPTION_KEY=$(gpg2f_derive_encryption_key "${SEED?}" "GPG2F_DECRYPTION_KEY_DERIVATION_CMD" "${GPG2F_DECRYPTION_KEY_DERIVATION_CMD?}"); then
        exec <&0
        return 1
    fi
    if ! gpg2f_run_gpg "decrypt" --decrypt --batch --passphrase-fd 3 --output - 3<<<"${ENCRYPTION_KEY?}"; then
        exec <&0
        return 1
    fi
    exec <&0
}

#-----------------------------------------------------------------------------------------------------------------------
# Generate a random seed
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_generate_random_seed() {
    local SEED
    if ! SEED=$(${GPG2F_GENERATED_SEED_CMD?}); then
        echo "ERROR: Failed to generate the seed (received an error from \"${GPG2F_GENERATED_SEED_CMD?}\")" >&2
        return 1
    elif [[ ${#SEED} -ne ${GPG2F_GENERATED_SEED_EXPECTED_LENGTH?} ]]; then
        echo "ERROR: Failed to generate the seed (\"${GPG2F_GENERATED_SEED_CMD?}\" generated ${#SEED} instead of ${GPG2F_GENERATED_SEED_EXPECTED_LENGTH?} characters)" >&2
        return 1
    fi
    echo -en "${SEED?}"
}

#-----------------------------------------------------------------------------------------------------------------------
# Normalize a seed by removing "\r" and replacing all "\n" with " ". Fails if the normalized seed is empty.
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... the seed to normalize
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_normalize_seed() {
    local SEED="$1"
    SEED="${SEED//$'\r'/}"
    SEED="${SEED//$'\n'/ }"
    if [[ -z "${SEED?}" ]]; then
        echo "ERROR: The normalized seed is empty" >&2
        return 1
    fi
    echo -n "${SEED?}"
}

#-----------------------------------------------------------------------------------------------------------------------
# Derive the encryption key. Fails if the derived encrytpion key is empty.
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... the seed
# $2 ... command variable name ("GPG2F_ENCRYPTION_KEY_DERIVATION_CMD" or "GPG2F_DECRYPTION_KEY_DERIVATION_CMD")
# #* ... the contents/commands of ${$2}
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_derive_encryption_key() {
    local SEED="$1"
    shift
    local COMMAND_VARIABLE="$1"
    shift
    local CONCATENATED_KEY=""
    local COMMAND CURRENT_KEY
    for COMMAND in "$@"; do
        if [[ -z "${COMMAND?}" ]]; then
            echo "ERROR: ${COMMAND_VARIABLE?} contains an empty command" >&2
            return 1
        elif ! CURRENT_KEY=$(eval ${COMMAND} <<<"${SEED?}"); then
            echo "ERROR: Failed to derive the key (\"${COMMAND?}\" returned an error)" >&2
            return 1
        elif ! gpg2f_validate_and_hash_derived_key "${CURRENT_KEY?}" "derived encryption key returned by \"${COMMAND?}\""; then
            return 1
        fi
        CONCATENATED_KEY="${CONCATENATED_KEY?}${CURRENT_KEY?}"
    done
    if ! gpg2f_validate_and_hash_derived_key "${CONCATENATED_KEY?}" "concatenated derived encryption key"; then
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Check the length of a derived key, hash it, check the lenght of the hashed key and print it.
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... the key
# $2 ... description (e.g. "concatenated key" or "key generated by [command]")
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_validate_and_hash_derived_key() {
    local KEY=$1
    local KEY_NAME=$2
    if [[ -z "${#KEY}" || ${#KEY} -lt ${GPG2F_MIN_DERIVED_KEY_LENGTH?} ]]; then
        echo "ERROR: The ${KEY_NAME?} is too short (${#KEY} characters instead of ${GPG2F_MIN_DERIVED_KEY_LENGTH?})" >&2
        return 1
    fi
    local HASHED_KEY
    if ! HASHED_KEY=$(${GPG2F_HASH_DERIVED_KEY_CMD?} <<<"${KEY?}"); then
        echo "ERROR: Failed to hash the ${KEY_NAME?} (\"${GPG2F_HASH_DERIVED_KEY_CMD?}\" returned an error)" >&2
        return 1
    elif [[ -z "${#HASHED_KEY}" || ${#HASHED_KEY} -lt ${GPG2F_MIN_DERIVED_KEY_LENGTH?} ]]; then
        echo "ERROR: The hash of the ${KEY_NAME?} is too short (${#HASHED_KEY} characters instead of ${GPG2F_MIN_DERIVED_KEY_LENGTH?})" >&2
        return 1
    fi
    echo -n "${HASHED_KEY?}"
}

#-----------------------------------------------------------------------------------------------------------------------
# Run GnuPG
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... operation description "encrypt" or "decrypt"
# $* ... pass-through GnuPG arguments
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_run_gpg() {
    local ENCRYPT_OR_DECRYPT="$1"
    shift
    local COMMAND_PREFIX=()
    case "$(uname -s)" in
    CYGWIN*)
        if [[ -n "$HOME" ]]; then
            COMMAND_PREFIX=(env HOME="$(cygpath "${HOME?}")")
        fi
        ;;
    esac
    # shellcheck disable=SC2086
    if "${COMMAND_PREFIX[@]}" ${GPG2F_GPG_CMD?} "$@"; then
        return 0
    else
        echo "ERROR: Failed to ${ENCRYPT_OR_DECRYPT?} the content (\"${GPG2F_GPG_CMD?} $*\" returned an error)" >&2
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Run the application
#-----------------------------------------------------------------------------------------------------------------------

gpg2f_run_and_unset "$@"

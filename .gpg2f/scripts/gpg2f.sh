#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Main program
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... "encrypt" or "decrypt"
# #* ... <no parameters> .............................. en-/decrypt from stdin to stdout
#     or [file] ....................................... en-/decrypt using the given file
#     or [--debug|-debug|--verbose|-verbose] .......... en-/decrypt stdin to stdout with stderr debug logging
#     or [--debug|-debug|--verbose|-verbose] [file] ... en-/decrypt using the given file with stderr debug logging
#     or [--help|-help|-h] ............................ display help syntax
#     or [--version|-version|-v] ...................... display version information
#-----------------------------------------------------------------------------------------------------------------------

# shellcheck disable=SC2317
function gpg2f_main() {

    # extract and validate parameters
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
    elif [[ "$1" == "--debug" || "$1" == "-debug" || "$1" == "--verbose" || "$1" == "-verbose" ]]; then
        export GPG2F_DEBUG=true
        shift
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

    # load and validate the configuration
    if [[ ! -f ".gpg2f/scripts/utils/load-and-validate-config.sh" ]]; then
        echo "ERROR: $(pwd)/.gpg2f/scripts/utils/load-and-validate-config.sh does not exist" >&2
        return 1
    elif ! . .gpg2f/scripts/utils/load-and-validate-config.sh; then
        return 1
    fi

    # execute the command
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
    echo "Syntax: encrypt.sh [--debug] [file]"
    echo "    or: decrypt.sh [--debug] [file]"
    echo ""
    echo "Encrypt stdin to the given [file] or decrypt the given [file] to stdout."
    echo "If [file] is not given, encrypt to stdout or decrypt from stdin."
    echo ""
    echo "The --debug option prints diagnostic information (including passwords and keys) to stderr."
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
# Encrypt from stdin
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... optional: file to encrypt to (instead of stdout)
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_encrypt() {

    # exgtract parameters
    local OUTPUT_FILE="$1"

    # generate the seed
    local SEED
    if ! SEED="$(gpg2f_generate_random_seed)"; then
        return 1
    fi

    # derive the encryption key
    local ENCRYPTION_KEY
    if ! ENCRYPTION_KEY=$(gpg2f_derive_encryption_key "${SEED?}" encrypt); then
        return 1
    fi

    # encrypt the content
    gpg2f_debug ""
    gpg2f_debug "Encrypting"
    gpg2f_debug "- seed: <${SEED?}>"
    gpg2f_debug "- encryption key: <${ENCRYPTION_KEY?}>"
    if [[ -n "${OUTPUT_FILE}" ]]; then
        mkdir -p "$(dirname "${OUTPUT_FILE?}")"
        exec >"${OUTPUT_FILE?}.tmp"
    fi
    echo "$SEED"
    if ! gpg2f_run_script .gpg2f/scripts/gpg/encrypt-stdin-symmetrically-to-stdout.sh --passphrase-fd 3 3<<<"${ENCRYPTION_KEY?}"; then
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

    # extract arguments
    local INPUT_FILE="$1"

    # point stdin to the input file (if present)
    if [[ -n "${INPUT_FILE?}" ]]; then
        exec <"${INPUT_FILE?}"
    fi

    # extract the seed
    local SEED
    IFS=$'\n' read -r SEED
    gpg2f_debug "Extracting the seed"
    gpg2f_debug "- seed: <${SEED?}>"
    if ! SEED=$(gpg2f_normalize_seed "${SEED?}"); then
        exec <&0
        return 1
    fi
    gpg2f_debug "- normalized: <${SEED?}>"

    # derive the encryption key
    if ! ENCRYPTION_KEY=$(gpg2f_derive_encryption_key "${SEED?}" decrypt); then
        exec <&0
        return 1
    fi

    # decrypt the content
    gpg2f_debug ""
    gpg2f_debug "Decrypting"
    gpg2f_debug "- seed: <${SEED?}>"
    gpg2f_debug "- encryption key: <${ENCRYPTION_KEY?}>"
    gpg2f_run_script .gpg2f/scripts/gpg/decrypt-stdin-to-stdout.sh --passphrase-fd 3 3<<<"${ENCRYPTION_KEY?}"
    local EXIT_CODE=$?
    exec <&0
    return ${EXIT_CODE}
}

#-----------------------------------------------------------------------------------------------------------------------
# Generate a random seed
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_generate_random_seed() {
    gpg2f_debug "Generating the random seed"
    gpg2f_debug "- command: ${GPG2F_GENERATE_SEED_CMD[*]}"
    local SEED
    if ! SEED=$("${GPG2F_GENERATE_SEED_CMD[@]}"); then
        echo "ERROR: Failed to generate the seed via: ${GPG2F_GENERATE_SEED_CMD[*]}" >&2
        return 1
    fi
    gpg2f_debug "- raw seed: <${SEED?}>"
    local NORMALIZED
    NORMALIZED=$(gpg2f_normalize_seed "${SEED?}")
    gpg2f_debug "- normalized seed: <${NORMALIZED?}>"
    if [[ ${#NORMALIZED} -ne ${GPG2F_EXPECTED_SEED_LENGTH?} ]]; then
        echo "ERROR: The generated random seed <${NORMALIZED}> has ${#NORMALIZED} characters (expected: ${GPG2F_EXPECTED_SEED_LENGTH?})" >&2
        return 1
    fi
    echo -n "${NORMALIZED?}"
}

#-----------------------------------------------------------------------------------------------------------------------
# Normalize a seed by removing "\r" and replacing all "\n" with " ". Fails if the normalized seed is empty.
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... the seed to normalize
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_normalize_seed() {
    local SEED="$1"
    local NORMALIZED
    NORMALIZED=$(gpg2f_remove_line_breaks "${SEED?}")
    if [[ -n "${NORMALIZED?}" ]]; then
        echo -n "${NORMALIZED?}"
    elif [[ -z "${SEED?}" ]]; then
        echo "ERROR: The seed is empty" >&2
        return 1
    else
        echo "ERROR: The seed contains only whitespace" >&2
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Derive the encryption key. Fails if the derived encrytpion key is empty.
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... the seed
# $2 ... operation ("encrypt" or "decrypt")
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_derive_encryption_key() {

    # extract parameters
    local SEED="$1"
    local OPERATION="$2"

    # obtain the commands for deriving and hashing the encryption key
    local DERIVE_KEY_COMMANDS DERIVE_KEY_COMMANDS_VARIABLE_NAME
    if [[ "${OPERATION?}" == "encrypt" ]]; then
        DERIVE_KEY_COMMANDS_VARIABLE_NAME="GPG2F_DERIVE_ENCRYPTION_KEY_CMD"
        DERIVE_KEY_COMMANDS=("${GPG2F_DERIVE_ENCRYPTION_KEY_CMD[@]}")
    elif [[ "${OPERATION?}" == "decrypt" ]]; then
        DERIVE_KEY_COMMANDS_VARIABLE_NAME="GPG2F_DERIVE_DECRYPTION_KEY_CMD"
        DERIVE_KEY_COMMANDS=("${GPG2F_DERIVE_DECRYPTION_KEY_CMD[@]}")
    else
        echo "ERROR: Invalid operation \"${OPERATION?}\" passed to gpg2f_derive_encryption_key (expected: \"encrypt\" or \"decrypt\")" >&2
        return 1
    fi

    # derive and concatenate all keys
    local COMMAND CURRENT_KEY CURRENT_HASHED_KEY
    local CONCATENATED_KEY=""
    local INDEX=0
    for COMMAND in "${DERIVE_KEY_COMMANDS[@]}"; do
        ((INDEX += 1))
        gpg2f_debug ""
        gpg2f_debug "Deriving encryption key ${INDEX?}"
        gpg2f_debug "- seed: <${SEED?}>"
        gpg2f_debug "- command: ${COMMAND?}"
        if [[ -z "${COMMAND[*]}" ]]; then
            echo "ERROR: ${DERIVE_KEY_COMMANDS_VARIABLE_NAME?} contains an empty string/command" >&2
            return 1
        elif ! CURRENT_KEY=$(eval ${COMMAND} <<<"${SEED?}"); then
            echo "ERROR: Command \"${COMMAND[*]}\" returned an error" >&2
            return 1
        elif ! CURRENT_HASHED_KEY=$(gpg2f_validate_and_hash_derived_key "${CURRENT_KEY?}" "${OPERATION?}" "derived key returned by \"${COMMAND[*]?}\""); then
            return 1
        fi
        CONCATENATED_KEY="${CONCATENATED_KEY?}${CURRENT_HASHED_KEY?}"
    done

    # hash the concatenated key
    gpg2f_debug ""
    gpg2f_debug "Hashing the concatenated key"
    if ! gpg2f_validate_and_hash_derived_key "${CONCATENATED_KEY?}" "${OPERATION?}" "concatenated derived key"; then
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Check the length of a derived key, hash it, check the lenght of the hashed key and print it.
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... the key to validate and hash
# $2 ... operation ("encrypt" or "decrypt")
# $3 ... description (e.g. "concatenated key" or "key generated by [command]")
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_validate_and_hash_derived_key() {

    # extract the parameters
    local KEY="$1"
    local OPERATION="$2"
    local KEY_NAME="$3"

    # obtain the commands for deriving and hashing the encryption key
    local HASH_KEY_COMMAND HASH_KEY_COMMAND_VARIABLE_NAME
    if [[ "${OPERATION?}" == "encrypt" ]]; then
        HASH_KEY_COMMAND_VARIABLE_NAME="GPG2F_HASH_ENCRYPTION_KEY_CMD"
        HASH_KEY_COMMAND=("${GPG2F_HASH_ENCRYPTION_KEY_CMD[@]}")
    elif [[ "${OPERATION?}" == "decrypt" ]]; then
        HASH_KEY_COMMAND_VARIABLE_NAME="GPG2F_HASH_DECRYPTION_KEY_CMD"
        HASH_KEY_COMMAND=("${GPG2F_HASH_DECRYPTION_KEY_CMD[@]}")
    else
        echo "ERROR: Invalid operation \"${OPERATION?}\" passed to gpg2f_validate_and_hash_derived_key (expected: \"encrypt\" or \"decrypt\")" >&2
        return 1
    fi

    # verify that the hash command is not empty
    if [[ -z "${HASH_KEY_COMMAND[*]}" ]]; then
        echo "ERROR: ${HASH_KEY_COMMAND_VARIABLE_NAME?} is empty" >&2
        return 1
    fi

    # normalize the key
    local NORMALIZED_KEY
    if ! NORMALIZED_KEY=$(gpg2f_remove_line_breaks "${KEY?}"); then
        echo "ERROR: Failed to normalize the derived key" >&2
        return 1
    fi
    gpg2f_debug "- key: <${KEY?}>"
    gpg2f_debug "- normalized: <${NORMALIZED_KEY?}>"
    if [[ -z "${#NORMALIZED_KEY}" || ${#NORMALIZED_KEY} -lt ${GPG2F_MIN_EXPECTED_KEY_LENGTH?} ]]; then
        echo "ERROR: The ${KEY_NAME?} is too short (${#NORMALIZED_KEY} characters instead of ${GPG2F_MIN_EXPECTED_KEY_LENGTH?})" >&2
        return 1
    fi

    # hash the normalized key
    gpg2f_debug "- command: ${HASH_KEY_COMMAND[*]}"
    local HASHED_KEY
    if ! HASHED_KEY=$("${HASH_KEY_COMMAND[@]}" <<<"${NORMALIZED_KEY?}"); then
        echo "ERROR: Failed to hash the ${KEY_NAME?} (\"${HASH_KEY_COMMAND[*]}\" returned an error)" >&2
        return 1
    fi
    gpg2f_debug "- hashed key: <${HASHED_KEY?}>"

    # normalize the hashed key
    local NORMALIZED_HASHED_KEY
    if ! NORMALIZED_HASHED_KEY=$(gpg2f_remove_line_breaks "${HASHED_KEY?}"); then
        echo "ERROR: Failed to normalize the hash of the derived key" >&2
        return 1
    fi
    gpg2f_debug "- normalized: <${NORMALIZED_HASHED_KEY?}>"
    if [[ -z "${#NORMALIZED_HASHED_KEY}" ]]; then
        echo "ERROR: The hash of the ${KEY_NAME?} is empty" >&2
        return 1
    elif [[ "${OPERATION?}" == "encrypt" && ${#NORMALIZED_HASHED_KEY} -ne ${GPG2F_EXPECTED_ENCRYPTION_HASH_LENGTH?} ]]; then
        echo "ERROR: The hash of the ${KEY_NAME?} has the wrong length (${#NORMALIZED_HASHED_KEY} characters instead of ${GPG2F_EXPECTED_ENCRYPTION_HASH_LENGTH?})" >&2
        return 1
    elif [[ "${OPERATION?}" == "decrypt" && ${#NORMALIZED_HASHED_KEY} -ne ${GPG2F_EXPECTED_DECRYPTION_HASH_LENGTH?} ]]; then
        echo "ERROR: The hash of the ${KEY_NAME?} has the wrong length (${#NORMALIZED_HASHED_KEY} characters instead of ${GPG2F_EXPECTED_DECRYPTION_HASH_LENGTH?})" >&2
        return 1
    fi
    echo -n "${NORMALIZED_HASHED_KEY?}"
}

#-----------------------------------------------------------------------------------------------------------------------
# Run the given command in the current bash
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... the script to run
# $* ... pass-through parameters
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_run_script() {

    # validate and extract parameters
    if [[ $# -eq 0 ]]; then
        echo "ERROR: No arguments passed to gpg2f_run_script" >&2
        return 1
    fi
    local SCRIPT="$1"
    shift

    # Verify that the script exists
    if [[ ! -f "${SCRIPT?}" ]]; then
        echo "ERROR: $(pwd)/${SCRIPT} does not exist" >&2
        return 1
    fi

    # run the command
    gpg2f_debug "- command:" "${COMMAND[@]}"
    # shellcheck disable=SC1090
    if ! . "${SCRIPT?}" "$@"; then
        echo "ERROR: Command ${SCRIPT?}" "$@" "returned an error" >&2
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Remove line breaks
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_remove_line_breaks() {
    local DATA="$*"
    DATA="${DATA//$'\r'/}"
    DATA="${DATA//$'\n'/ }"
    echo -n "${DATA?}"
}

#-----------------------------------------------------------------------------------------------------------------------
# Print a debug message
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_debug() {
    if [[ "${GPG2F_DEBUG}" == "true" ]]; then
        echo -e "[DEBUG] $*" >&2
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Run a command with a pop-up notification
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... the notification message
# $* ... pass-through command to execute
#-----------------------------------------------------------------------------------------------------------------------

function with-notification() {
    local MESSAGE="$1"
    shift
    local EXIT_CODE=0
    local PID=""
    if [[ -n "${MESSAGE?}" && -n "${GPG2F_NOTIFICATION_CMD[*]}" ]]; then
        exec 3> >(
            local DELAY
            if DELAY=$(gpg2f_get_notification_delay); then
                sleep "${DELAY?}"
            fi
            "${GPG2F_NOTIFICATION_CMD[@]}" "${MESSAGE?}"
        )
        PID=$!
    fi
    "$@"
    EXIT_CODE=$?
    if [[ -n "${MESSAGE?}" && -n "${GPG2F_NOTIFICATION_CMD[*]}" ]]; then
        exec 3>&-
    fi
    if [[ -n "${PID?}" ]]; then
        kill ${PID?} >/dev/null 2>&1
    fi
    return ${EXIT_CODE?}
}

#-----------------------------------------------------------------------------------------------------------------------
# Get the configured notification delay
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_get_notification_delay() {
    local OPTION
    for OPTION in ${NOTIFICATION_OPTIONS} ${GPG2F_DEFAULT_NOTIFICATION_OPTIONS?}; do
        if [[ "${OPTION?}" =~ "delay=" ]]; then
            echo "${OPTION//delay=/}"
            return 0
        fi
    done
    return 1
}

#-----------------------------------------------------------------------------------------------------------------------
# Run the application and unset all functions and variables
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_run_and_unset() {
    local FUNCTIONS_TO_UNSET=(
        gpg2f_main
        gpg2f_display_syntax_help
        gpg2f_display_version_and_copyright
        gpg2f_encrypt
        gpg2f_decrypt
        gpg2f_generate_random_seed
        gpg2f_normalize_seed
        gpg2f_derive_encryption_key
        gpg2f_validate_and_hash_derived_key
        gpg2f_run_script
        gpg2f_remove_line_breaks
        gpg2f_debug
        with-notification
        gpg2f_get_notification_delay
        gpg2f_run_and_unset
    )
    local CONFIG_VARIABLES_TO_UNSET=(
        GPG2F_GPG_CMD
        GPG2F_GPG_SYMMETRIC_ENCRYPTION_OPTIONS
        GPG2F_GPG_ASYMMETRIC_ENCRYPTION_OPTIONS
        GPG2F_GPG_DECRYPTION_OPTIONS
        GPG2F_DERIVE_DECRYPTION_KEY_CMD
        GPG2F_DERIVE_ENCRYPTION_KEY_CMD
        GPG2F_MIN_EXPECTED_KEY_LENGTH
        GPG2F_GENERATE_SEED_CMD
        GPG2F_EXPECTED_SEED_LENGTH
        GPG2F_HASH_DECRYPTION_KEY_CMD
        GPG2F_HASH_ENCRYPTION_KEY_CMD
        GPG2F_EXPECTED_HASH_LENGTH
        GPG2F_NOTIFICATION_CMD
        GPG2F_DEFAULT_NOTIFICATION_OPTIONS
    )
    local OTHER_VARIABLES_TO_UNSET=(
        GPG2F_DEBUG
    )
    local EXIT_CODE
    gpg2f_main "$@"
    EXIT_CODE=$?
    unset "${FUNCTIONS_TO_UNSET?}" "${CONFIG_VARIABLES_TO_UNSET?}" "${OTHER_VARIABLES_TO_UNSET?}"
    unset FUNCTIONS_TO_UNSET CONFIG_VARIABLES_TO_UNSET OTHER_VARIABLES_TO_UNSET
    return ${EXIT_CODE?}
}

gpg2f_run_and_unset "$@"

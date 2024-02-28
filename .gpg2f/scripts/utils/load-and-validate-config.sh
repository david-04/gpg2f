#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Load and validate the configuration
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_load_and_validate_config() {
    if ! gpg2f_load_config; then
        return 1
    fi
    local CONFIG_ERRORS
    CONFIG_ERRORS=$(gpg2f_validate_config)
    if [[ -n "${CONFIG_ERRORS}" ]]; then
        echo -n "${CONFIG_ERRORS}" >&2
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Load the configuration
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_load_config() {
    # shellcheck disable=SC1091
    if [[ ! -f "./settings.sh" ]]; then
        if [[ -f "./.gpg2f/templates/config/settings.example.sh" ]]; then
            cp ./.gpg2f/templates/config/settings.example.sh ./settings.sh
        else
            echo "ERROR: Neither $(pwd)/settings.sh nor $(pwd)/.gpg2f/templates/config/settings.example.sh exists"
            return 1
        fi
    fi

    if [[ -f "./settings.sh" ]]; then
        # shellcheck disable=SC1091
        source "./settings.sh"
    else
        echo "ERROR: $(pwd)/settings.sh does not exists"
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Validate the configuration
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_validate_config() {
    if ! declare -p GPG2F_GPG_CMD >/dev/null 2>&1; then
        echo "ERROR: GPG2F_GPG_CMD is not set"
    elif [[ ! "$(declare -p GPG2F_GPG_CMD)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_GPG_CMD is not an array"
    elif [[ -z "${GPG2F_GPG_CMD[*]}" ]]; then
        echo "ERROR: GPG2F_GPG_CMD is not set"
    fi
    if ! declare -p GPG2F_GPG_SYMMETRIC_ENCRYPTION_OPTIONS >/dev/null 2>&1; then
        echo "ERROR: GPG2F_GPG_SYMMETRIC_ENCRYPTION_OPTIONS is not set"
    elif [[ ! "$(declare -p GPG2F_GPG_SYMMETRIC_ENCRYPTION_OPTIONS)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_GPG_SYMMETRIC_ENCRYPTION_OPTIONS is not an array"
    fi
    if ! declare -p GPG2F_GPG_ASYMMETRIC_ENCRYPTION_OPTIONS >/dev/null 2>&1; then
        echo "ERROR: GPG2F_GPG_ASYMMETRIC_ENCRYPTION_OPTIONS is not set"
    elif [[ ! "$(declare -p GPG2F_GPG_ASYMMETRIC_ENCRYPTION_OPTIONS)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_GPG_ASYMMETRIC_ENCRYPTION_OPTIONS is not an array"
    fi
    if ! declare -p GPG2F_GPG_DECRYPTION_OPTIONS >/dev/null 2>&1; then
        echo "ERROR: GPG2F_GPG_DECRYPTION_OPTIONS is not set"
    elif [[ ! "$(declare -p GPG2F_GPG_DECRYPTION_OPTIONS)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_GPG_DECRYPTION_OPTIONS is not an array"
    fi
    if ! declare -p GPG2F_GENERATE_SEED_CMD >/dev/null 2>&1; then
        echo "ERROR: GPG2F_GENERATE_SEED_CMD is not set"
    elif [[ ! "$(declare -p GPG2F_GENERATE_SEED_CMD)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_GENERATE_SEED_CMD is not an array"
    elif [[ -z "${GPG2F_GENERATE_SEED_CMD[*]}" ]]; then
        echo "ERROR: GPG2F_GENERATE_SEED_CMD is not set"
    fi
    if [[ -z "${GPG2F_EXPECTED_SEED_LENGTH}" ]]; then
        echo "ERROR: GPG2F_EXPECTED_SEED_LENGTH is not set"
    elif ! [ "${GPG2F_EXPECTED_SEED_LENGTH?}" -eq "${GPG2F_EXPECTED_SEED_LENGTH?}" ] 2>/dev/null; then
        echo "ERROR: GPG2F_EXPECTED_SEED_LENGTH is not a number"
    elif [[ "${GPG2F_EXPECTED_SEED_LENGTH?}" -lt 1 ]]; then
        echo "ERROR: GPG2F_EXPECTED_SEED_LENGTH must be a positive number"
    fi
    if ! declare -p GPG2F_DERIVE_DECRYPTION_KEY_CMD >/dev/null 2>&1; then
        echo "ERROR: GPG2F_DERIVE_DECRYPTION_KEY_CMD is not set"
    elif [[ ! "$(declare -p GPG2F_DERIVE_DECRYPTION_KEY_CMD)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_DERIVE_DECRYPTION_KEY_CMD is not an array"
    elif [[ -z "${GPG2F_DERIVE_DECRYPTION_KEY_CMD[*]}" ]]; then
        echo "ERROR: GPG2F_DERIVE_DECRYPTION_KEY_CMD is not set"
    fi
    if ! declare -p GPG2F_DERIVE_ENCRYPTION_KEY_CMD >/dev/null 2>&1; then
        echo "ERROR: GPG2F_DERIVE_ENCRYPTION_KEY_CMD is not set"
    elif [[ ! "$(declare -p GPG2F_DERIVE_ENCRYPTION_KEY_CMD)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_DERIVE_ENCRYPTION_KEY_CMD is not an array"
    elif [[ -z "${GPG2F_DERIVE_ENCRYPTION_KEY_CMD[*]}" ]]; then
        echo "ERROR: GPG2F_DERIVE_ENCRYPTION_KEY_CMD is not set"
    fi
    if [[ -z "${GPG2F_MIN_EXPECTED_KEY_LENGTH}" ]]; then
        echo "ERROR: GPG2F_MIN_EXPECTED_KEY_LENGTH is not set"
    elif ! [ "${GPG2F_MIN_EXPECTED_KEY_LENGTH?}" -eq "${GPG2F_MIN_EXPECTED_KEY_LENGTH?}" ] 2>/dev/null; then
        echo "ERROR: GPG2F_MIN_EXPECTED_KEY_LENGTH is not a number"
    elif [[ "${GPG2F_MIN_EXPECTED_KEY_LENGTH?}" -lt 1 ]]; then
        echo "ERROR: GPG2F_MIN_EXPECTED_KEY_LENGTH must be a positive number"
    fi
    if ! declare -p GPG2F_HASH_DECRYPTION_KEY_CMD >/dev/null 2>&1; then
        echo "ERROR: GPG2F_HASH_DECRYPTION_KEY_CMD is not set"
    elif [[ ! "$(declare -p GPG2F_HASH_DECRYPTION_KEY_CMD)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_HASH_DECRYPTION_KEY_CMD is not an array"
    elif [[ -z "${GPG2F_HASH_DECRYPTION_KEY_CMD[*]}" ]]; then
        echo "ERROR: GPG2F_HASH_DECRYPTION_KEY_CMD is not set"
    fi
    if ! declare -p GPG2F_HASH_ENCRYPTION_KEY_CMD >/dev/null 2>&1; then
        echo "ERROR: GPG2F_HASH_ENCRYPTION_KEY_CMD is not set"
    elif [[ ! "$(declare -p GPG2F_HASH_ENCRYPTION_KEY_CMD)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_HASH_ENCRYPTION_KEY_CMD is not an array"
    elif [[ -z "${GPG2F_HASH_ENCRYPTION_KEY_CMD[*]}" ]]; then
        echo "ERROR: GPG2F_HASH_ENCRYPTION_KEY_CMD is not set"
    fi
    if [[ -z "${GPG2F_EXPECTED_DECRYPTION_HASH_LENGTH}" ]]; then
        echo "ERROR: GPG2F_EXPECTED_DECRYPTION_HASH_LENGTH is not set"
    elif ! [ "${GPG2F_EXPECTED_DECRYPTION_HASH_LENGTH?}" -eq "${GPG2F_EXPECTED_DECRYPTION_HASH_LENGTH?}" ] 2>/dev/null; then
        echo "ERROR: GPG2F_EXPECTED_DECRYPTION_HASH_LENGTH is not a number"
    elif [[ "${GPG2F_EXPECTED_DECRYPTION_HASH_LENGTH?}" -lt 1 ]]; then
        echo "ERROR: GPG2F_EXPECTED_DECRYPTION_HASH_LENGTH must be a positive number"
    fi
    if [[ -z "${GPG2F_EXPECTED_ENCRYPTION_HASH_LENGTH}" ]]; then
        echo "ERROR: GPG2F_EXPECTED_ENCRYPTION_HASH_LENGTH is not set"
    elif ! [ "${GPG2F_EXPECTED_ENCRYPTION_HASH_LENGTH?}" -eq "${GPG2F_EXPECTED_ENCRYPTION_HASH_LENGTH?}" ] 2>/dev/null; then
        echo "ERROR: GPG2F_EXPECTED_ENCRYPTION_HASH_LENGTH is not a number"
    elif [[ "${GPG2F_EXPECTED_ENCRYPTION_HASH_LENGTH?}" -lt 1 ]]; then
        echo "ERROR: GPG2F_EXPECTED_ENCRYPTION_HASH_LENGTH must be a positive number"
    fi
    if ! declare -p GPG2F_NOTIFICATION_CMD >/dev/null 2>&1; then
        echo "ERROR: GPG2F_NOTIFICATION_CMD is not set"
    elif [[ ! "$(declare -p GPG2F_NOTIFICATION_CMD)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_NOTIFICATION_CMD is not an array"
    fi
    if ! declare -p GPG2F_DEFAULT_NOTIFICATION_OPTIONS >/dev/null 2>&1; then
        echo "ERROR: GPG2F_DEFAULT_NOTIFICATION_OPTIONS is not set"
    elif [[ ! "$(declare -p GPG2F_DEFAULT_NOTIFICATION_OPTIONS)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_DEFAULT_NOTIFICATION_OPTIONS is not an array"
    fi
}

function gpg2f_unset_load_and_validate_config() {
    unset gpg2f_load_and_validate_config gpg2f_load_config gpg2f_validate_config gpg2f_unset_load_and_validate_config
}

# shellcheck disable=SC2317
if gpg2f_load_and_validate_config "$@" >&2; then
    gpg2f_unset_load_and_validate_config
    return 0 2>/dev/null || exit 0
else
    gpg2f_unset_load_and_validate_config
    return 1 2>/dev/null || exit 1
fi

#!/usr/bin/env bash

#-----------------------------------------------------------------------------------------------------------------------
# Load and validate the configuration
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_load_and_validate_config() {
    if ! gpg2f_load_config; then
        return 1
    elif ! gpg2f_validate_config; then
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Load the configuration
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_load_config() {
    # shellcheck disable=SC1091
    if [[ -f "./settings.sh" ]]; then
        source "./settings.sh"
    elif [[ -f "./.gpg2f/examples/settings.example.sh" ]]; then
        source "./.gpg2f/examples/settings.example.sh"
    else
        echo "ERROR: Neither $(pwd)/settings.sh nor $(pwd)/.gpg2f/examples.settings.example.sh exists"
        return 1
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Validate the configuration
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_validate_config() {
    local EXIT_CODE=0
    if [[ -z "${GPG2F_GPG_CMD[*]}" ]]; then
        echo "ERROR: GPG2F_GPG_CMD is not set"
        EXIT_CODE=1
    fi
    if [[ ! "$(declare -p GPG2F_GPG_SYMMETRIC_ENCRYPTION_OPTIONS)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_GPG_SYMMETRIC_ENCRYPTION_OPTIONS is not set"
        EXIT_CODE=1
    fi
    if [[ ! "$(declare -p GPG2F_GPG_ASYMMETRIC_ENCRYPTION_OPTIONS)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_GPG_ASYMMETRIC_ENCRYPTION_OPTIONS is not set"
        EXIT_CODE=1
    fi
    if [[ ! "$(declare -p GPG2F_GPG_DECRYPTION_OPTIONS)" =~ "declare -a" ]]; then
        echo "ERROR: GPG2F_GPG_DECRYPTION_OPTIONS is not set"
        EXIT_CODE=1
    fi

    if [[ -z "${GPG2F_GENERATE_SEED_CMD}" ]]; then
        echo "ERROR: GPG2F_GENERATE_SEED_CMD is not set"
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
    if [[ -z "${GPG2F_HASH_DERIVED_ENCRYPTION_KEY_CMD}" ]]; then
        echo "ERROR: GPG2F_HASH_DERIVED_ENCRYPTION_KEY_CMD is not set"
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
    return ${EXIT_CODE?}
}

function gpg2f_unset_load_and_validate_config() {
    unset gpg2f_load_and_validate_config gpg2f_load_config gpg2f_validate_config gpg2f_unset_laod_and_validate_config gpg2f_unset_load_and_validate_config
}

# shellcheck disable=SC2317
if gpg2f_load_and_validate_config "$@" >&2; then
    gpg2f_unset_load_and_validate_config
    return 0 2>/dev/null || exit 0
else
    gpg2f_unset_load_and_validate_config
    return 1 2>/dev/null || exit 1
fi

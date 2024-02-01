#!/usr/bin/env bash

GPG2F_PASSWORDSTORE_SHIM_SCRIPT_DIR="$(dirname "$(realpath "$0")")"

#-----------------------------------------------------------------------------------------------------------------------
# Redirect passwordstore GPG operations to gpg-sym2f (if applicable)
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_passwordstore_shim_main() {

    #-------------------------------------------------------------------------------------------------------------------
    # General commands
    #-------------------------------------------------------------------------------------------------------------------

    # Get GnuPG version: --version

    if [[ "$*" == "--version" ]]; then
        gpg2f_passwordstore_shim_run_gpg2 "$@"
        return $?
    fi

    #-------------------------------------------------------------------------------------------------------------------
    # QtPass commands
    #-------------------------------------------------------------------------------------------------------------------

    # Init passwordstore: --no-tty --with-colons --with-fingerprint --list-keys"

    if [[ "$*" == "--no-tty --with-colons --with-fingerprint --list-keys" ]]; then
        gpg2f_passwordstore_shim_list_keys_with_colons_and_fingerprint
        return $?
    fi

    # Init passwordstore: --no-tty --with-colons --with-fingerprint --list-secret-keys

    if [[ "$*" == "--no-tty --with-colons --with-fingerprint --list-secret-keys" ]]; then
        gpg2f_passwordstore_shim_list_secret_keys_with_colons_and_fingerprint
        return $?
    fi

    # Add password: --batch -eq --output file.gpg -r WEUSESYMMETRICENCRYPTIONANDDONOTNEEDAKEY -

    if [[ $# -eq 7 && "$1 $2 $3 $5 $7" == "--batch -eq --output -r -" ]]; then
        gpg2f_passwordstore_shim_encrypt "$4"
        return $?
    fi

    # Modify password: --batch -eq --output file.gpg -r WEUSESYMMETRICENCRYPTIONANDDONOTNEEDAKEY --yes -

    if [[ $# -eq 8 && "$1 $2 $3 $5 $7 $8" == "--batch -eq --output -r --yes -" ]]; then
        gpg2f_passwordstore_shim_encrypt "$4"
        return $?
    fi

    # Decrypt password: -d --quiet --yes --no-encrypt-to --batch --use-agent file.gpg

    if [[ $# -eq 7 && "$1 $2 $3 $4 $5 $6" == "-d --quiet --yes --no-encrypt-to --batch --use-agent" ]]; then
        gpg2f_passwordstore_shim_decrypt "$7"
        return $?
    fi

    #-------------------------------------------------------------------------------------------------------------------
    # Browserpass commands
    #-------------------------------------------------------------------------------------------------------------------

    # Decrypt password: --decrypt --yes --quiet --batch -

    if [[ "$*" == "--decrypt --yes --quiet --batch -" ]]; then
        gpg2f_passwordstore_shim_decrypt
        return $?
    fi

    # Encrypt password: --encrypt --yes --quiet --batch --output file.gpg --recipient WEUSESYMMETRICENCRYPTIONANDDONOTNEEDAKEY

    if [[ $# -eq 8 && "$1 $2 $3 $4 $5 $7" == "--encrypt --yes --quiet --batch --output --recipient" ]]; then
        gpg2f_passwordstore_shim_encrypt "$6"
        return $?
    fi

    #-------------------------------------------------------------------------------------------------------------------
    # Fall back to the real gpg2 for everything else
    #-------------------------------------------------------------------------------------------------------------------

    {
        echo "Unknown command:"
        echo -n "- working directory: "
        pwd
        echo "- command: gpg2 $*"
    } >>"/tmp/gpg-shim-passwordstore.log"

    gpg2f_passwordstore_shim_run_gpg2 "$@"
    return $?
}

#-----------------------------------------------------------------------------------------------------------------------
# List a virtual/non-existent public key
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_passwordstore_shim_list_keys_with_colons_and_fingerprint() {
    echo "tru::1:1706424002:0:3:1:5"
    echo "pub:u:3072:1:C22C2F452E8AC7B1:1706423979:::u:::escaESCA::::::23::0:"
    echo "fpr:::::::::WEUSESYMMETRICENCRYPTIONANDDONOTNEEDAKEY:"
    echo "uid:u::::1706423979::AB28A8B7A77B2EDD18D31F6D5A7EC35D262616AA::GPG 2F <noreply@gpg2f.github.io>::::::::::0:"
    echo "sub:u:3072:1:A154755D016202A0:1706423979::::::esa::::::23:"
    echo "fpr:::::::::FFEA0A8C76546489108CBA8DA154755D016202A0:"
}

#-----------------------------------------------------------------------------------------------------------------------
# List a virtual/non-existent private key
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_passwordstore_shim_list_secret_keys_with_colons_and_fingerprint() {
    echo "sec:u:3072:1:C22C2F452E8AC7B1:1706423979:::u:::escaESCA:::+:::23::0:"
    echo "fpr:::::::::WEUSESYMMETRICENCRYPTIONANDDONOTNEEDAKEY:"
    echo "grp:::::::::DE099AFBC3E6CCC81D3BFCB015C92BD746C9F4F8:"
    echo "uid:u::::1706423979::AB28A8B7A77B2EDD18D31F6D5A7EC35D262616AA::GPG 2F <noreply@gpg2f.github.io>::::::::::0:"
    echo "ssb:u:3072:1:A154755D016202A0:1706423979::::::esa:::+:::23:"
    echo "fpr:::::::::FFEA0A8C76546489108CBA8DA154755D016202A0:"
    echo "grp:::::::::CF202271AB1E60F257E9949D33650D415913E17B:"
}

#-----------------------------------------------------------------------------------------------------------------------
# Encrypt content
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... optional: output file (encrypt to stdout if not set)
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_passwordstore_shim_encrypt() {
    gpg2f_passwordstore_shim_encrypt_or_decrypt "encrypt.sh" "$1"
    return $?
}

#-----------------------------------------------------------------------------------------------------------------------
# Decrypt content
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... optional: input file (decrypt from stdin if not set)
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_passwordstore_shim_decrypt() {
    gpg2f_passwordstore_shim_encrypt_or_decrypt "decrypt.sh" "$1"
    return $?
}

#-----------------------------------------------------------------------------------------------------------------------
# Encrypt or decrypt content
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... name of the script ("encrypt.sh" or "decrypt.sh")
# $2 ... input file (decrypt stdin if not set or an empty string)
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_passwordstore_shim_encrypt_or_decrypt() {
    local FILE SCRIPT SCRIPT_DIRECTORY
    FILE=$(gpg2f_passwordstore_shim_get_absolute_path "$2")
    SCRIPT="$1"
    SCRIPT_DIRECTORY="$(gpg2f_passwordstore_shim_find_script_directory "${SCRIPT?}" "${FILE?}")"
    if [[ -z "${SCRIPT_DIRECTORY?}" ]]; then
        echo "ERROR: Failed to locate ${SCRIPT?}" >&2
        return 1
    fi
    if ! cd "${SCRIPT_DIRECTORY?}"; then
        echo "ERROR: Failed to change to directory ${SCRIPT_DIRECTORY?}" >&2
        return 1
    fi
    if [[ -z "${FILE?}" ]]; then
        # shellcheck disable=SC1090
        . "${SCRIPT?}"
        return $?
    else
        # shellcheck disable=SC1090
        . "${SCRIPT?}" "${FILE?}"
        return $?
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Get the given file's absolute path
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... optional: file as relative or absolute path
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_passwordstore_shim_get_absolute_path() {
    if [[ -n "$1" ]]; then
        realpath -m "$1"
    fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Locate the encrypt.sh script in the closest parent directory of the given file (or the current directory if not set)
#-----------------------------------------------------------------------------------------------------------------------
# $1 ... name of the script ("encrypt.sh" or "decrypt.sh")
# $2 ... optional: absolute path of the file to encrypt or decrypt
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_passwordstore_shim_find_script_directory() {
    local DIRECTORY
    if [[ -n "$2" ]]; then
        DIRECTORY="$(dirname "$2")"
    elif [[ -n "${GPG2F_PASSWORDSTORE_SHIM_SCRIPT_DIR?}" ]]; then
        DIRECTORY="${GPG2F_PASSWORDSTORE_SHIM_SCRIPT_DIR?}/../.."
    else
        DIRECTORY="$(pwd)"
    fi
    DIRECTORY="$(realpath -m "${DIRECTORY?}")"
    for _ in {1..100}; do
        if [[ -f "${DIRECTORY}/$1" ]]; then
            echo "${DIRECTORY}"
            return 0
        fi
        DIRECTORY="$(realpath -m "${DIRECTORY?}/..")"
    done
    return 1
}

#-----------------------------------------------------------------------------------------------------------------------
# Run gpg2
#-----------------------------------------------------------------------------------------------------------------------
# $@ ... parameters to pass on to gpg2
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_passwordstore_shim_run_gpg2() {
    case "$(uname -s)" in
    CYGWIN*)
        if [[ -n "$HOME" ]]; then
            env HOME="$(cygpath "${HOME?}")" gpg2 "$@"
            return $?
        fi
        ;;
    esac
    gpg2 "$@"
    return $?
}

#-----------------------------------------------------------------------------------------------------------------------
# Run the application
#-----------------------------------------------------------------------------------------------------------------------

function gpg2f_passwordstore_shim_unset() {
    local GLOBAL_VARIABLES=(
        GPG2F_PASSWORDSTORE_SHIM_SCRIPT_DIR
    )
    local FUNCTIONS=(
        gpg2f_passwordstore_shim_main
        gpg2f_passwordstore_shim_list_keys_with_colons_and_fingerprint
        gpg2f_passwordstore_shim_list_secret_keys_with_colons_and_fingerprint
        gpg2f_passwordstore_shim_encrypt
        gpg2f_passwordstore_shim_decrypt
        gpg2f_passwordstore_shim_encrypt_or_decrypt
        gpg2f_passwordstore_shim_get_absolute_path
        gpg2f_passwordstore_shim_find_script_directory
        gpg2f_passwordstore_shim_run_gpg2
        gpg2f_passwordstore_shim_unset
    )
    unset "${FUNCTIONS?}" "${GLOBAL_VARIABLES?}"
}

if gpg2f_passwordstore_shim_main "$@"; then
    gpg2f_passwordstore_shim_unset
    # shellcheck disable=SC2317
    return 0 2>/dev/null || exit 0
else
    gpg2f_passwordstore_shim_unset
    # shellcheck disable=SC2317
    return 1 2>/dev/null || exit 1
fi

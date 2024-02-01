#!/usr/bin/env bash
# shellcheck disable=SC2317

[[ "$1" == "encrypt.sh" ]] && shift

if [[ ! -f "encrypt.sh" ]]; then
    echo "ERROR: encrypt.sh can only be invoked in its own directory (current working directory: $(pwd))" >&2
    return 1 2>/dev/null || exit 1
elif [[ ! -f ".gpg2f/scripts/gpg2f.sh" ]]; then
    echo "ERROR: $(pwd)/.gpg2f/scripts/gpg2f.sh does not exist" >&2
    return 1 2>/dev/null || exit 1
elif ! . .gpg2f/scripts/gpg2f.sh encrypt "$@"; then
    return 1 2>/dev/null || exit 1
fi

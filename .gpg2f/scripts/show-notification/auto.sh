#!/usr/bin/env bash

if which java >/dev/null; then
    . .gpg2f/scripts/show-notification/java.sh "$@"
elif which powershell >/dev/null; then
    . .gpg2f/scripts/show-notification/powershell.sh "$@"
fi

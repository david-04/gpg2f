#!/usr/bin/env bash

if which java >/dev/null; then
    . .gpg2f/runtime/show-notification-java.sh "$*"
elif which powershell >/dev/null; then
    . .gpg2f/runtime/show-notification-powershell.sh "$*"
fi

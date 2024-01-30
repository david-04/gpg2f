#!/usr/bin/env bash
# shellcheck disable=SC2317

if which java >/dev/null; then
    java -cp .gpg2f/runtime/notifications PopUpWindow "$*"
elif which powershell >/dev/null; then
    env GPG2F_NOTIFICATION_TEXT="$*" powershell -noprofile -noninteractive -File .gpg2f/runtime/notifications/balloon-tip.ps1
fi

#!/usr/bin/env bash
# shellcheck disable=SC2317

if which powershell >/dev/null; then
    env GPG2F_NOTIFICATION_TEXT="$*" powershell -noprofile -noninteractive -File .gpg2f/runtime/notifications/balloon-tip.ps1
fi

#!/usr/bin/env bash

env GPG2F_NOTIFICATION_TEXT="$*" powershell -noprofile -noninteractive -File .gpg2f/runtime/notifications/balloon-tip.ps1

#!/usr/bin/env bash

NOTIFICATION="$*" powershell -noprofile -noninteractive -File .gpg2f/scripts/show-notification/powershell/balloon-tip.ps1

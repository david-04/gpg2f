@echo off
set GPG2F_DECRYPT_DIRECTORY=%~dp0
env %GPG2F_DECRYPT_DIRECTORY:\=/%decrypt.sh %*

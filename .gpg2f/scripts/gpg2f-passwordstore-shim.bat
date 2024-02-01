@echo off
set GPG2F_PASSWORD_STORE_SHIM_DIRECTORY=%~dp0
env %GPG2F_PASSWORD_STORE_SHIM_DIRECTORY:\=/%/gpg2f-passwordstore-shim.sh %*

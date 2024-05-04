@echo off
set GPG2F_ENCRYPT_DIRECTORY=%~dp0
env %GPG2F_ENCRYPT_DIRECTORY:\=/%encrypt %*

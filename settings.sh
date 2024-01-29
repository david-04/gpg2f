#-----------------------------------------------------------------------------------------------------------------------
# Challenge-response
#-----------------------------------------------------------------------------------------------------------------------
# - Set to "yubikey-slot-1" or "yubikey-slot-2" to use a Yubikey
# - Set to a GPG-encrypted file with the hex secret to calculate the response locally with openssl
# - Leave empty to disable challenge-reponse (use the static password only)
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_CFG_CHALLENGE_RESPONSE_ENCRYPT="yubikey-slot-2"
export GPG2F_CFG_CHALLENGE_RESPONSE_DECRYPT="${GPG2F_CFG_CHALLENGE_RESPONSE_ENCRYPT?}"

#-----------------------------------------------------------------------------------------------------------------------
# Static password
#-----------------------------------------------------------------------------------------------------------------------
# - Set to a GPG-encrypted file containing the static password
# - Leave empty to disable the static password (use challenge-reponse only)
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_CFG_STATIC_PASSWORD_ENCRYPT=".gpg2f/keys/static-password.gpg"
export GPG2F_CFG_STATIC_PASSWORD_DECRYPT="${GPG2F_CFG_STATIC_PASSWORD_ENCRYPT?}"

#-----------------------------------------------------------------------------------------------------------------------
# Base command and common options to invoke the GnuPG
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_CFG_GPG_COMMAND="gpg2 --quiet --no-permission-warning"

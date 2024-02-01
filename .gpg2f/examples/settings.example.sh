#-----------------------------------------------------------------------------------------------------------------------
# Base command for invoking GnuPG.
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_GPG_CMD="gpg2 --quiet --no-permission-warning --batch --cipher-algo AES256"

#-----------------------------------------------------------------------------------------------------------------------
# Commands to derive the encryption key. Each command works as follows:
#
#   1. If required for the operation, read the seed from stdin
#   2. Generate a key (either by deriving it from the seed or by acquiring a static secret)
#   3. Print the derived key to stdout
#
# Each command's output is hashed and all hashes are concatenated. The concatenated hash is then hashed again, forming
# the effective encryption key. Key derivation commands can:
#
#   - Calculate the seed's HMAC SHA1 via YubiKey's challenge response (the first parameter is the YubiKey slot):
#     ". .gpg2f/derive-key/yubikey-hallenge-rsponse.sh 1"
#   - Calculate the seed's HMAC SHA1 locally with openssl, using a secreted from a GnuPG-encrypted file:
#     ". .gpg2f/derive-key/openssl-hmac-sha1.sh .gpg2f/templates/keys/hmac-sha1-secret.gpg"
#   - Extract a static password from a GnuPG-encrypted file
#     ". .gpg2f/gpg/decrypt.sh .gpg2f/templates/keys/static-password.gpg"
#
# A pop-up notification can be added to commands that require user interaction (like pressing the YubiKey button or
# entering a password):
#
#   ". with-notification 'Please touch the YubiKey' . .gpg2f/derive-key/yubikey-hallenge-rsponse.sh 1"
#
# To pass notification options, set the NOTIFICATION_OPTOINS variable:
#
#   "NOTIFICATION_OPTIONS='delay=1s timeout=5s' . with-notification 'Please touch the YubiKey' [...]"
#
# GPG2F_ENCRYPTION_KEY_DERIVATION_CMD is usually the same as GPG2F_DECRYPTION_KEY_DERIVATION_CMD. They only need to be
# different while rotation keys or changing the key derivation algorithms.
#
# GPG2F_MIN_DERIVED_KEY_LENGTH specifies the minimum length of each key (individually). This length requirement must be
# satisfied by the plain key and by its hashed version. The setting is used to protect against malfunctions where the
# scripts generate keys that are too short/unsecure.
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_DECRYPTION_KEY_DERIVATION_CMD=(
    "NOTIFICATION_OPTIONS='a b c' with-notification 'Touch the YubiKey' . .gpg2f/runtime/derive-key/yubikey-challenge-response.sh 2"
)

export GPG2F_ENCRYPTION_KEY_DERIVATION_CMD=("${GPG2F_DECRYPTION_KEY_DERIVATION_CMD[@]}")

export GPG2F_MIN_DERIVED_KEY_LENGTH=20

#-----------------------------------------------------------------------------------------------------------------------
# A command that generates a random seed and prints it to stdout. The expected string length is used to verify that the
# seed has the correct length (to pretect against any malfunction of the seed generator command).
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_GENERATED_SEED_CMD=". .gpg2f/runtime/generate-seed/openssl-hex.sh 63"
export GPG2F_GENERATED_SEED_EXPECTED_LENGTH="126"

#-----------------------------------------------------------------------------------------------------------------------
# A command to hash a derived key.
#-----------------------------------------------------------------------------------------------------------------------
# . .gpg2f/runtime/hash-derived-key/disabled.sh ... do not has the key
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_HASH_DERIVED_KEY_CMD=". .gpg2f/runtime/hash-derived-key/openssl-sha512.sh"

#-----------------------------------------------------------------------------------------------------------------------
# Command to display GUI pop-up notifications
#-----------------------------------------------------------------------------------------------------------------------
# .gpg2f/runtime/show-notification/auto.sh ......... automatically pick an option
# .gpg2f/runtime/show-notification/java.sh ......... use Java to display a window
# .gpg2f/runtime/show-notification/powershell.sh ... use PowerShell to display a balloon tip/pop-up
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_NOTIFICATION_CMD=". .gpg2f/runtime/show-notification/auto.sh"

#-----------------------------------------------------------------------------------------------------------------------
# Notification options are specific to the notifier. The PowerShell notifier ignores all options. Java supports the
# following options:
#
#    background-color=#c425dd ......... window background color (Java notifier only)
#    delay=1s ......................... delay before showing the notification
#    font-size=24 ..................... text size (Java notifier only)
#    position=[N|NE|E|SE|S|SW|W|NW] ... window position (Java notifier only)
#    timeout=5s ....................... auto-hide the notification after this duration (Java notifier only)
#
# Options are specified as space-separated key=value pairs, for example:
#
#    "delay=1s timeout=5s"
#
# There must not be any whitespace within a key-value pair.
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_DEFAULT_NOTIFICATION_OPTIONS=""

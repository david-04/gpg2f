#-----------------------------------------------------------------------------------------------------------------------
# GnuPG command and options
#-----------------------------------------------------------------------------------------------------------------------
# GPG2F_GPG_CMD ............................. base command for all operations (encrypt/decrypt/symmetric/asymmetric)
# GPG2F_GPG_SYMMETRIC_ENCRYPTION_OPTIONS .... additional options/parameters when encrypting symmetrically
# GPG2F_GPG_ASYMMETRIC_ENCRYPTION_OPTIONS ... additional options/parameters when encrypting asymmetrically
# GPG2F_GPG_DECRYPTION_OPTIONS .............. additional options/parameters when decrypting
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_GPG_CMD=(gpg2 --quiet --no-permission-warning --batch)

export GPG2F_GPG_SYMMETRIC_ENCRYPTION_OPTIONS=(--armor --symmetric --cipher-algo AES256)
export GPG2F_GPG_ASYMMETRIC_ENCRYPTION_OPTIONS=(--armor)
export GPG2F_GPG_DECRYPTION_OPTIONS=(--decrypt)

#-----------------------------------------------------------------------------------------------------------------------
# Random seed generation
#-----------------------------------------------------------------------------------------------------------------------
# Every time content is encrypted, a random seed is generated. It is used to derive one or more keys that are eventually
# concatenated and hashed into the actual/effective encryption key. The command below is used to generate the seed:
#
#   . .gpg2f/scripts/generate-seed/openssl-hex.sh 63
#

# A command that generates a random seed and prints it to stdout. The expected string length is used to verify that the
# seed has the correct length (to pretect against any malfunction of the seed generator command).
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_GENERATE_SEED_CMD=(. .gpg2f/scripts/generate-seed/openssl-hex.sh 63)
export GPG2F_GENERATED_SEED_EXPECTED_LENGTH=126

#-----------------------------------------------------------------------------------------------------------------------
# Derive the encryption key(s)
#-----------------------------------------------------------------------------------------------------------------------
# Every time content is encrypted, a random seed is generated
# Each command works as follows:
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
# GPG2F_DERIVE_ENCRYPTION_KEY_CMD is usually the same as GPG2F_DERIVE_DECRYPTION_KEY_CMD. They only need to be
# different while rotation keys or changing the key derivation algorithms.
#
# GPG2F_MIN_DERIVED_KEY_LENGTH specifies the minimum length of each key (individually). This length requirement must be
# satisfied by the plain key and by its hashed version. The setting is used to protect against malfunctions where the
# scripts generate keys that are too short/unsecure.
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_DERIVE_DECRYPTION_KEY_CMD=(
    "NOTIFICATION_OPTIONS='delay~=1s' with-notification 'Touch the YubiKey' . .gpg2f/scripts/derive-key/yubikey-challenge-response.sh 2"
    ".gpg2f/scripts/gpg/decrypt-file-to-stdout.sh .gpg2f/examples/keys/static-password.example.gpg"
)

export GPG2F_DERIVE_ENCRYPTION_KEY_CMD=("${GPG2F_DERIVE_DECRYPTION_KEY_CMD[@]}")

# export GPG2F_DERIVE_ENCRYPTION_KEY_CMD=(
#     ". .gpg2f/scripts/derive-key/openssl-hmac-sha1.sh .gpg2f/examples/keys/hmac-sha1-secret.example.gpg"
#     ".gpg2f/scripts/gpg/decrypt-file-to-stdout.sh .gpg2f/examples/keys/static-password.example.gpg"
# )

export GPG2F_MIN_DERIVED_KEY_LENGTH=20

#-----------------------------------------------------------------------------------------------------------------------
# A command to hash a derived key. Each key is hashed individually. The hashes are then concatenated and the result is
# hashed into the final encryption key. encryption_key = hash(hash(derived_key1) + hash(derived_key2) + ...)
#-----------------------------------------------------------------------------------------------------------------------
# cat ................................................. don not hash (use concatenated derived keys directly)
# . .gpg2f/scripts/calculate-hash/openssl-sha512.sh ... generate SHA-512 via OpenSSL
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_HASH_DECRYPTION_KEY_CMD=(. .gpg2f/scripts/calculate-hash/openssl-sha256.sh)
export GPG2F_HASH_ENCRYPTION_KEY_CMD=("${GPG2F_HASH_DECRYPTION_KEY_CMD[@]}")

#-----------------------------------------------------------------------------------------------------------------------
# Command to display GUI pop-up notifications
#-----------------------------------------------------------------------------------------------------------------------
# .gpg2f/scripts/show-notification/auto.sh ......... automatically pick an option
# .gpg2f/scripts/show-notification/java.sh ......... use Java to display a window
# .gpg2f/scripts/show-notification/powershell.sh ... use PowerShell to display a balloon tip/pop-up
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_NOTIFICATION_CMD=(. .gpg2f/scripts/show-notification/auto.sh)

#-----------------------------------------------------------------------------------------------------------------------
# Default options to customize the notification pop-up. The are specified as space-separated key=value pairs:
#
#   "delay=1s timeout=5s"
#
# Values can contain whitespace but no equal sign. Options are notifier-specific. Not all notifiers support all of them.
#
#   background-color=#c425dd ..................  window background color (Java notifier only)
#   delay=1s .................................. delay before showing the notification
#   fly-in-duration=2s ........................ duration during which the dialog slides into view (Java notifier only)
#   font=Segoe UI ............................. font name  (Java notifier only)
#   font-size=24 .............................. text size (Java notifier only)
#   padding=20 ................................ horizontal and vertical padding between the text and the window borders
#   timeout=5s ................................ auto-hide the notification after this duration (Java notifier only)
#   window-position=[C|N|NE|E|SE|S|SW|W|NW] ... window position (Java notifier only, default is C [center])
#
# The default options can be overriden by setting the environment variable NOTIFICATION_OPTIONS in any of the
# GPG2F_DERIVE_DECRYPTION_KEY_CMD commands
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_DEFAULT_NOTIFICATION_OPTIONS=(delay=1s)

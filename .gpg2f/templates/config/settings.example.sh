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
# Every time content is encrypted, a random seed is generated. It is used to derive the encryption key(s). The command
# specified in GPG2F_GENERATE_SEED_CMD must generate a random seed and print it to stdout. GPG2F_EXPECTED_SEED_LENGTH
# is used to protect against malfunctions in the seed generator.
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_GENERATE_SEED_CMD=(. .gpg2f/scripts/generate-seed/openssl-hex.sh 63)
export GPG2F_EXPECTED_SEED_LENGTH=126

#-----------------------------------------------------------------------------------------------------------------------
# Key derivation
#-----------------------------------------------------------------------------------------------------------------------
# GPG2F_DERIVE_DECRYPTION_KEY_CMD can contain multiple commands to generate one or more derived keys. Each command
# receives the seed from stdin and prints the derived key to stdout.
#
#   - Calculate the seed's HMAC SHA-1 via YubiKey's challenge-response (the first parameter is the YubiKey slot):
#     ". .gpg2f/scripts/derive-key/yubikey-challenge-response.sh 1"
#   - Calculate the seed's HMAC SHA-1 locally with OpenSSL, using a secret from a GnuPG-encrypted file:
#     ". .gpg2f/scripts/derive-key/openssl-hmac-sha1.sh .gpg2f/templates/keys/hmac-secret-key.example.gpg"
#   - Extract a static password from a GnuPG-encrypted file (without using the seed)
#     ". .gpg2f/scripts/gpg/decrypt-file-to-stdout.sh .gpg2f/templates/keys/static-key.example.gpg"
#
# The "with-notification" function can be used to show a pop-up for commands that require user interaction:
#
#   - Show a pop-up notification with standard options
#     "with-notification 'Please touch the YubiKey' . .gpg2f/scripts/derive-key/yubikey-challenge-response.sh 1"
#   - Show a pop-up notification with additional/overridden options
#     "NOTIFICATION_OPTIONS='delay=1s timeout=5s' with-notification 'Please touch the YubiKey' [...]"
#
# GPG2F_DERIVE_ENCRYPTION_KEY_CMD and GPG2F_DERIVE_DECRYPTION_KEY_CMD only need to be configured differently while
# adding/removing/changing key derivation methods. It allows decrypting with the old derivation methods while encrypting
# with the new ones. GPG2F_MIN_EXPECTED_KEY_LENGTH specifies the minimum length of each derived key. It protects against
# malfunctions in key derivation commands.
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_DERIVE_DECRYPTION_KEY_CMD=(
    ".gpg2f/scripts/gpg/decrypt-file-to-stdout.sh .gpg2f/templates/keys/static-key.example.gpg"
    ". .gpg2f/scripts/derive-key/openssl-hmac-sha1.sh .gpg2f/templates/keys/hmac-secret-key.example.gpg"
    # To use a YubiKey, replace the line above with the one below
    # "with-notification 'Touch the YubiKey' . .gpg2f/scripts/derive-key/yubikey-challenge-response.sh 1"
)
export GPG2F_DERIVE_ENCRYPTION_KEY_CMD=("${GPG2F_DERIVE_DECRYPTION_KEY_CMD[@]}")
export GPG2F_MIN_EXPECTED_KEY_LENGTH=20

#-----------------------------------------------------------------------------------------------------------------------
# Hashing
#-----------------------------------------------------------------------------------------------------------------------
# The commands below are used to hash derived keys. Each command must read the key from stdin and print its hash to
# stdout.
#
#   . .gpg2f/scripts/calculate-hash/openssl-sha256.sh ... generate a SHA-256 hash with OpenSSL
#   . .gpg2f/scripts/calculate-hash/openssl-sha512.sh ... generate a SHA-512 hash with OpenSSL
#   cat ................................................. do not hash (use derived keys as they are)
#
# GPG2F_HASH_DECRYPTION_KEY_CMD and GPG2F_HASH_ENCRYPTION_KEY_CMD only need to be configured differently while changing
# the hash algorithm. It allows decrypting with the old hash algorithm while encrypting with the new one.
# GPG2F_EXPECTED_DECRYPTION_HASH_LENGTH and GPG2F_EXPECTED_ENCRYPTION_HASH_LENGTH specify the expected length of each
# calculated hash. They protect against malfunctions in the hash commands.
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_HASH_DECRYPTION_KEY_CMD=(. .gpg2f/scripts/calculate-hash/openssl-sha512.sh)
export GPG2F_HASH_ENCRYPTION_KEY_CMD=("${GPG2F_HASH_DECRYPTION_KEY_CMD[@]}")

export GPG2F_EXPECTED_DECRYPTION_HASH_LENGTH=128
export GPG2F_EXPECTED_ENCRYPTION_HASH_LENGTH="${GPG2F_EXPECTED_DECRYPTION_HASH_LENGTH?}"

#-----------------------------------------------------------------------------------------------------------------------
# Pop-up notifications
#-----------------------------------------------------------------------------------------------------------------------
# Pop-up notifications can be used to indicate required user interaction (like touching the YubiKey). The following
# notifiers are available:
#
#   .gpg2f/scripts/show-notification/auto.sh ......... automatically pick an option
#   .gpg2f/scripts/show-notification/java.sh ......... use Java to display a window (requires Java to be installed)
#   .gpg2f/scripts/show-notification/powershell.sh ... use PowerShell to display a balloon tip/pop-up
#
# GPG2F_DEFAULT_NOTIFICATION_OPTIONS contains default options to customize the notification pop-up. They are specified
# as an array of key=value pairs. Values (like the font name) can contain blanks. Most options are only supported by
# the Java notifier. The PowerShell notifier only supports the "delay" option.
#
#   background-color=#c425dd .................. window background color
#   delay=1s .................................. delay before showing the notification
#   fly-in-duration=2s ........................ duration during which the dialog slides into view
#   font=Segoe UI ............................. font name
#   font-size=24 .............................. text size
#   padding=20 ................................ padding between the text and the window
#   timeout=5s ................................ auto-hide the notification after this duration
#   window-position=[C|N|NE|E|SE|S|SW|W|NW] ... window position (default is C for center)
#
# The default options can be overriden by setting the environment variable NOTIFICATION_OPTIONS before calling the
# with-notification function.
#-----------------------------------------------------------------------------------------------------------------------

export GPG2F_NOTIFICATION_CMD=(. .gpg2f/scripts/show-notification/auto.sh)
export GPG2F_DEFAULT_NOTIFICATION_OPTIONS=(delay=1s fly-in-duration=2s window-position=N)

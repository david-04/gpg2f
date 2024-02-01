#!/usr/bin/env bash

openssl dgst -sha512 | sed 's/^[^=]*= *//'

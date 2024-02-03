#!/usr/bin/env bash

openssl dgst -sha256 | sed 's/^[^=]*= *//'

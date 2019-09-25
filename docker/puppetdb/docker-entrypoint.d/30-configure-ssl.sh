#!/bin/sh

if [ ! -f "${SSLDIR}/certs/${CERTNAME}.pem" ] && [ "$USE_PUPPETSERVER" = true ]; then
  set -e

  DNS_ALT_NAMES="${HOSTNAME},${DNS_ALT_NAMES}" /ssl.sh "$CERTNAME"
  openssl pkcs8 -inform PEM -outform DER -in ${SSLDIR}/private_keys/${CERTNAME}.pem -topk8 -nocrypt -out ${SSLDIR}/private_keys/${CERTNAME}.pk8

  # make sure Java apps running as puppetdb can read these files
  chown -R puppetdb:puppetdb ${SSLDIR}

  # and that they're further restricted
  chmod u=rwx,g=,o= ${SSLDIR}/private_keys
  chmod u=rw,g=,o= ${SSLDIR}/private_keys/*

  chmod u=rwx,g=,o= ${SSLDIR}/certs
  chmod u=rw,g=,o= ${SSLDIR}/certs/*
fi

#!/bin/bash
set -e

# Generate first CA
openssl req -x509 -newkey rsa:4096 -days 365 -nodes \
  -keyout first-ca.key -out first-ca.crt \
  -subj "/CN=First Test CA" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -addext "basicConstraints=critical,CA:TRUE"

# Generate second CA
openssl req -x509 -newkey rsa:4096 -days 365 -nodes \
  -keyout second-ca.key -out second-ca.crt \
  -subj "/CN=Second Test CA" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -addext "basicConstraints=critical,CA:TRUE"

# Generate client cert signed by first CA
openssl genrsa -out first-client.key 4096
openssl req -new -key first-client.key -out first-client.csr \
  -subj "/CN=First Test Client"

openssl x509 -req -in first-client.csr -days 365 \
  -CA first-ca.crt -CAkey first-ca.key -CAcreateserial \
  -out first-client.crt

# Generate second client cert signed by first CA (for rotation test)
openssl genrsa -out first-client-new.key 4096
openssl req -new -key first-client-new.key -out first-client-new.csr \
  -subj "/CN=First Test Client New"

openssl x509 -req -in first-client-new.csr -days 365 \
  -CA first-ca.crt -CAkey first-ca.key -CAcreateserial \
  -out first-client-new.crt

# Generate client cert signed by second CA
openssl genrsa -out second-client.key 4096
openssl req -new -key second-client.key -out second-client.csr \
  -subj "/CN=Second Test Client"

openssl x509 -req -in second-client.csr -days 365 \
  -CA second-ca.crt -CAkey second-ca.key -CAcreateserial \
  -out second-client.crt

# Clean up CSR files
rm -f *.csr *.srl

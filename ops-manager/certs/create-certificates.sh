#!/bin/bash

# Generate a CA cert/key, then combine them into a .pem
openssl genrsa -out mongodb-ca.key 4096
openssl req -new -x509 -days 1826 -key mongodb-ca.key -out mongodb-ca.crt -config conf/openssl-ca.cnf  -subj "/C=IE/ST=Leinster/L=Dublin/O=Support Example/OU=Customer Engineering/CN=om.internal"
cat mongodb-ca.crt mongodb-ca.key > mongodb-ca.pem

# Generate a server certificate for *.om.internal and *.alt.internal and combine them into a .pem file
openssl genrsa -out server.om.internal.key 4096
openssl req -new -key server.om.internal.key -out server.om.internal.csr -config conf/openssl-server.cnf -subj "/C=IE/ST=Leinster/L=Dublin/O=Support Example/OU=Customer Engineering/CN=server.om.internal"
openssl x509 -req -days 365 -in server.om.internal.csr -CA mongodb-ca.crt -CAkey mongodb-ca.key -CAcreateserial -out server.om.internal.crt -extfile conf/openssl-server.cnf -extensions v3_req
cat server.om.internal.crt server.om.internal.key > server.om.internal.pem

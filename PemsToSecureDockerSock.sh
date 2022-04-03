#!/usr/bin/env bash

# This script autogenerates the client and server pem files needed to secure the docker sock (port 2376)

set -e

PASSWD=$(uuidgen | cut -c1-8)

echo -n "Enter the FQDN of your docker pod: "
read FQDN

NAME=$(echo $FQDN | awk -F '.' '{print $1}')
CLIDIR="${NAME}_clientkeys"
SERVDIR="${NAME}_serverkeys"

mkdir -p $SERVDIR;cd $SERVDIR

expect <<- DONE
  set timeout -1
  spawn screen openssl genrsa -aes256 -out ca-key.pem 4096
  expect "*pass*"
  send -- "$PASSWD\r"
  expect "*pass*"
  send -- "$PASSWD\r"
  spawn screen openssl req -new -x509 -days 3650 -key ca-key.pem -sha256 -out ca.pem
  expect "*pass*"
  send -- "$PASSWD\r"
  expect "Country*"
  send -- "US\r" 
  expect "State*"
  send -- "MA\r" 
  expect "Locality*"
  send -- "Boston\r" 
  expect "Organization*"
  send -- "YourOrg\r" 
  expect "Organizational*"
  send -- "DevOps\r" 
  expect "Common*"
  send -- "$FQDN\r"     
  expect "Email*"
  send -- "devops@YourOrg.com\r"
  expect eof
DONE
  
openssl genrsa -out server-key.pem 4096

openssl req -subj "/CN=${FQDN}" -sha256 -new -key server-key.pem -out server.csr

echo subjectAltName = DNS:${FQDN},IP:127.0.0.1 >> extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf
 
expect <<- DONE
  set timeout -1
  spawn screen openssl x509 -req -days 3650 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf
  expect "*pass*"
  send -- "$PASSWD\r"
  expect eof
DONE

chmod -v 0444 *.pem

cd ..

mkdir -p $CLIDIR;cd $CLIDIR

openssl genrsa -out key.pem 4096

openssl req -subj '/CN=client' -new -key key.pem -out client.csr

echo extendedKeyUsage = clientAuth > extfile-client.cnf

expect <<- DONE
  set timeout -1
  spawn screen openssl x509 -req -days 3650 -sha256 -in client.csr -CA ../${SERVDIR}/ca.pem -CAkey ../${SERVDIR}/ca-key.pem -CAcreateserial -out cert.pem -extfile extfile-client.cnf
  expect "*pass*"
  send -- "$PASSWD\r"
  expect eof
DONE

chmod -v 0444 *.pem

cp ../${SERVDIR}/ca.pem .

rm -vf .srl client.csr ../${SERVDIR}/server.csr ../${SERVDIR}/extfile.cnf extfile-client.cnf ../${SERVDIR}/ca-key.pem ../${SERVDIR}/ca.srl

echo "Client and Server Keys Generated for $FQDN"

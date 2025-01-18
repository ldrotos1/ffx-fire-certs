#!/bin/bash
echo "|-----------------------------------------------------------------------|"
echo "| This script will create the certificates for the ffx fire application |"
echo "|-----------------------------------------------------------------------|"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CERT_DIR="${SCRIPT_DIR}/certs"
PASSWORD=password
FILENMAE_PREFIX=ffx-fire

CA_KEY="${CERT_DIR}/${FILENMAE_PREFIX}-root-CA.key"
CA_CRT="${CERT_DIR}/${FILENMAE_PREFIX}-root-CA.crt"
CA_SUBJ="//SKIP=skip/CN=fairfaxfire.gov/emailAddress=admin@fairfaxfire.gov/C=US/ST=Virginia/L=Fairfax/O=Fairfax County/OU=Fire and Rescue"

SERV_NAME="localhost"
SERV_KEY="${CERT_DIR}/${FILENMAE_PREFIX}-server.key"
SERV_CSR="${CERT_DIR}/${FILENMAE_PREFIX}-server.csr"
SERV_CRT="${CERT_DIR}/${FILENMAE_PREFIX}-server.crt"
SERV_P12="${CERT_DIR}/${FILENMAE_PREFIX}-server.p12"
SERV_JKS="${CERT_DIR}/${FILENMAE_PREFIX}-server-keystore.jks"
SERV_SUBJ="//SKIP=skip/CN=localhost/emailAddress=admin@fairfaxfire.gov/C=US/ST=Virginia/L=Fairfax/O=Fairfax County/OU=Fire and Rescue"

TS_JKS="${CERT_DIR}/${FILENMAE_PREFIX}-truststore.jks"

echo "--------- Removing any previously generated cert files ----------"
find $CERT_DIR -type f ! \( -name '*.md' \) -delete

echo "--------- Creating root certificate ----------"
winpty openssl req -x509 -sha256 -days 3650 -newkey rsa:4096 -keyout $CA_KEY -out $CA_CRT -subj "${CA_SUBJ}" -passin "pass:${PASSWORD}" -passout "pass:${PASSWORD}"

echo "--------- Creating server certicate CSR ----------"
winpty openssl req -new -newkey rsa:4096 -keyout $SERV_KEY -out $SERV_CSR -subj "${SERV_SUBJ}" -passin "pass:${PASSWORD}" -passout "pass:${PASSWORD}"

echo "--------- Signing server certificate ----------"
winpty openssl x509 -req -CA $CA_CRT -CAkey $CA_KEY -in $SERV_CSR -out $SERV_CRT -passin "pass:${PASSWORD}" -days 365 -CAcreateserial -extfile "${SCRIPT_DIR}/localhost.ext"

echo "--------- Importing server certifcate into keystore ----------"
winpty openssl pkcs12 -export -out $SERV_P12 -name $SERV_NAME -inkey $SERV_KEY -in $SERV_CRT -passin "pass:${PASSWORD}" -passout "pass:${PASSWORD}"
keytool -importkeystore -srckeystore $SERV_P12 -srcstoretype PKCS12 -destkeystore $SERV_JKS -deststoretype JKS -srcstorepass $PASSWORD -deststorepass $PASSWORD

echo "--------- Creating the truststore ----------"
keytool -import -trustcacerts -noprompt -alias ca -ext san=dns:localhost,ip:127.0.0.1 -file $CA_CRT -keystore $TS_JKS -srcstorepass $PASSWORD -deststorepass $PASSWORD

echo "--------- Creating client certificates ----------"
jsonlist=$(jq -r '.users' "${SCRIPT_DIR}/users.json")
for row in $(echo "${jsonlist}" | jq -r '.[] | @base64'); do
  _jq()
  {
    echo ${row} | base64 --decode -i | jq -r ${1}
  }

  CLIENT_NAME="$(_jq '.name')"
  CLIENT_EMAIL="$(_jq '.email')"
  CLIENT_FILE_NAME="${CLIENT_NAME/" "/"-"}"

  CLIENT_CERT_NAME="${CLIENT_FILE_NAME}-client"
  CLIENT_KEY="${CERT_DIR}/${CLIENT_FILE_NAME}-client.key"
  CLIENT_CSR="${CERT_DIR}/${CLIENT_FILE_NAME}-client.csr"
  CLIENT_CRT="${CERT_DIR}/${CLIENT_FILE_NAME}-client.crt"
  CLIENT_P12="${CERT_DIR}/${CLIENT_FILE_NAME}-client.p12"
  CLIENT_SUBJ="//SKIP=skip/CN=${CLIENT_NAME}/emailAddress=${CLIENT_EMAIL}/C=US/ST=Virginia/L=Fairfax/O=Fairfax County/OU=Fire and Rescue"
  
  winpty openssl req -new -newkey rsa:4096 -nodes -keyout $CLIENT_KEY -out $CLIENT_CSR -subj "${CLIENT_SUBJ}" -passin "pass:${PASSWORD}" -passout "pass:${PASSWORD}"
  winpty openssl x509 -req -CA $CA_CRT -CAkey $CA_KEY -in $CLIENT_CSR -out $CLIENT_CRT -days 365 -CAcreateserial -passin "pass:${PASSWORD}"
  winpty openssl pkcs12 -export -out $CLIENT_P12 -name $CLIENT_CERT_NAME -inkey $CLIENT_KEY -in $CLIENT_CRT -passin "pass:${PASSWORD}" -passout "pass:${PASSWORD}"
  echo "--- Created client certification for ${CLIENT_NAME}" 

done

echo "--------- Script completed ----------"
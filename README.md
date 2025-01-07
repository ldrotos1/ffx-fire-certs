# ffx-fire-certs
Contains scripts for creating certificates to be used for mutual TLS during local development

## Requirments
Windows OS<br/>
OpenSSL<br/>
Java 17<br/>
Java Keytool command on path<br/>

## Key Generated Artifacts

### Keystore 
Creates a keystore file, *ffx-fire-server-keystore.jks*, that contains a self signed server certificate. This keystore is loaded on backend REST servers and the certificate is presented to clients as part of establishing an SSL connection.

### Truststore
Creates a truststore file, *ffx-fire-server-truststore.jks*, that contains the root CA certifcate that is used to sign all the certificates. This truststore is loaded on the backend REST servers and is use to verfiy certificates that are presented by client as part of client-side authentication.

### Root CA
Creates a root CA file, *ffx-fire-root-CA.crt*, that can be installed in a web browser as a trusted certificate. This is used to by the browser to verify the certificate that is presented by the backend REST server.

### Client-side Certificate
Creates a client-side certificate, *ffx-fire-client.p12*, that can be installed in a web browser as a client certificate. This certificate is presented to the backend REST server to authenticate the client.

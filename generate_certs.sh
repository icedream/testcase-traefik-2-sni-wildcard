#!/bin/bash -e

generate_key() {
	key="$1"
	echo "Generating key: $key" >&2
	mkdir -vp "$(dirname "$key")"
	openssl ecparam -out "$1" -name secp384r1 -genkey
}

generate_csr() {
	key="$1"
	csr="$2"
	subj="$3"
	san="$4"
	echo "Generating CSR: $csr" >&2
	mkdir -vp "$(dirname "$csr")"
	openssl req -new \
		-subj "$subj" \
		-key "$key" \
		-out "$csr" \
		-addext "subjectAltName=$san"
}

generate_cert() {
	key="$1"
	cert="$2"
	subj="$3"
	echo "Generating certificate: $cert" >&2
	mkdir -vp "$(dirname "$cert")"
	openssl req -new -x509 \
		-sha256 \
		-days 14 \
		-subj "$subj" \
		-key "$key" \
		-out "$cert" \
		-addext "basicConstraints=CA:TRUE, pathlen:0"
}

sign_csr() {
	csr="$1"
	cacert="$2"
	cakey="$3"
	cert="$4"
	san="$5"
	echo "Signing certificate: $cert" >&2
	mkdir -vp "$(dirname "$cert")"
	openssl x509 -req \
		-sha256 \
		-days 7 \
		-in "$csr" \
		-CA "$cacert" \
		-CAkey "$cakey" \
		-CAcreateserial \
		-extfile <(
			echo "extendedKeyUsage = serverAuth"
			echo "subjectAltName = $san"
		) \
		-out "$cert"
}

sign_cert() {
	key="$1"
	cacert="$2"
	cakey="$3"
	cert="$4"
	subj="$5"
	san="$6"
	csr="$(mktemp)"
	generate_csr "$key" "$csr" "$subj" "$san"
	sign_csr "$csr" "$cacert" "$cakey" "$cert" "$san"
	rm "$csr"
}

bundle_cert() {
	cacert="$1"
	cert="$2"
	bundlecert="$3"
	mkdir -vp "$(dirname "$bundlecert")"
	cat "$cacert" "$cert" > "$bundlecert"
}

# Generate CA key and cert
cadir="./ca"
cakey="$cadir/privkey.pem"
cacert="$cadir/cert.pem"
generate_key "$cakey"
generate_cert "$cakey" "$cacert" "/CN=Test CA"

# Generate SNI default key and cert
defaultdir="./certs/default"
defaultkey="$defaultdir/privkey.pem"
defaultcert="$defaultdir/cert.pem"
defaultcsr="$defaultdir/csr.pem"
defaultbundle="$defaultdir/fullchain.pem"
generate_key "$defaultkey"
sign_cert "$defaultkey" "$cacert" "$cakey" "$defaultcert" "/CN=traefik.localhost" "DNS:traefik.localhost,DNS:*.traefik.localhost"

# Generate specific key and cert
specificdir="./certs/specific"
specifickey="$specificdir/privkey.pem"
specificcert="$specificdir/cert.pem"
specificcsr="$specificdir/csr.pem"
specificbundle="$specificdir/fullchain.pem"
generate_key "$specifickey"
sign_cert "$specifickey" "$cacert" "$cakey" "$specificcert" "/CN=sub.traefik.localhost" "DNS:sub.traefik.localhost,DNS:*.sub.traefik.localhost"

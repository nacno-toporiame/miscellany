#!/usr/bin/env bash
# This script is based on the script for NetworkManager (nmcli) of the Universität Greifswald 
# https://github.com/heinlo/easyroam_iwctl and https://github.com/einetuer/nix-easyroam are referred to
# For the configuration of the eduroam profile for iwd a file is created in /var/lib/iwd/eduroam.8021x

set -e

# check if we are root
if [[ $EUID -ne 0 ]]; then
    echo "You must be root to run easyroam_iwd.sh." 1>&2
    exit 100
fi

if [ -z "$1" ]; then
        echo ""
        echo "Your pkcs12 file is missed as input parameter."
        echo ""
        exit 1
else
        InputFile="$1"
fi

# check for iwctl and iwd.service
if ! type iwctl >/dev/null 2>&1; then
        echo ""
        echo "ERROR: iwctl not found!" >&2
        echo ""
        exit 1
fi

LegacyOption=
OpenSSLversion=$(openssl version | awk '{print $2}' | sed -e 's/\..*$//')
if [ "$OpenSSLversion" -eq "3" ]; then
        LegacyOption="-legacy"
fi

# check pkcs12 file
if ! openssl pkcs12 -in "$InputFile" $LegacyOption -info -noenc -passin pass: > /dev/null 2>&1; then
        echo ""
        echo "ERROR: The given input file does not seem to be a valid pkcs12 file."
        echo ""
        exit 1
fi

# extract key, cert, ca and identity
Identity=$(openssl pkcs12 -in "$InputFile" $LegacyOption -passin pass: -nokeys \
             | openssl x509 -noout -subject | sed -e 's/.*=//' -e 's/\s*//')
CACert=$(openssl pkcs12 -in "$InputFile" $LegacyOption -passin pass: -nokeys -cacerts \
           | sed -n '/^-/,/^-/p')
ClientCert=$(openssl pkcs12 -in "$InputFile" $LegacyOption -passin pass: -nokeys -clcerts \
               | sed -n '/^-/,/^-/p')
ClientKey=$(openssl pkcs12 -in "$InputFile" $LegacyOption -passin pass: -nocerts -noenc \
               | sed -n '/^-/,/^-/p')
# Embed into IWD provisioning file
WLANName="eduroam"
IWDProfPath="/var/lib/iwd/${WLANName}.8021x"
bash -c "tee ${IWDProfPath} &>/dev/null <<-EOF
	[Settings]
	AutoConnect=false
	[Security]
	EAP-Method=TLS
	EAP-Identity=${Identity}
	EAP-TLS-ServerDomainMask=easyroam.eduroam.de
	EAP-TLS-ClientCert=embed:easyroam_client_cert.pem
	EAP-TLS-ClientKey=embed:easyroam_client_key.pem
	EAP-TLS-CACert=embed:easyroam_ca_cert.pem
	[@pem@easyroam_ca_cert.pem]
	${CACert}
	[@pem@easyroam_client_cert.pem]
	${ClientCert}
	[@pem@easyroam_client_key.pem]
	${ClientKey}
EOF" && echo "Created iwd profile for ${WLANName} in ${IWDProfPath}"

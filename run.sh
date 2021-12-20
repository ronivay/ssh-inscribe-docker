#!/bin/bash

stop() {
    rm -f /ssh-agent/ssh_inscribe_agent.sock
    pkill /usr/local/bin/ssh-inscribe
}

trap stop EXIT TERM

# create conf and base directory if missing
mkdir -p /opt/sshi/conf

# generate configuration
set -a

AUTH_TYPE=${AUTH_TYPE:-"file"}
FILE_USER=${FILE_USER:-"test"}
FILE_PASSWORD=${FILE_PASSWORD:-"testpassword"}
AUTH_REALM=${AUTH_REALM:-"default realm"}
AUTH_FRIENDLY_NAME=${AUTH_FRIENDLY_NAME:-"default auth"}
MAX_CERT_LIFETIME=${MAX_CERT_LIFETIME:-"24h"}
DEFAULT_CERT_LIFETIME=${DEFAULT_CERT_LIFETIME:-"8h"}

SSL_CERT=${SSL_CERT:-/opt/sshi/ssl/cert.pem}
SSL_KEY=${SSL_KEY:-/opt/sshi/ssl/key.pem}

CA_KEY=${CA_KEY:-/opt/sshi/ssl/ca-key.pem}
CA_KEY_AUTOADD=${CA_KEY_AUTOADD:-"true"}
CA_KEY_GENERATE=${CA_KEY_GENERATE:-"true"}

if [[ ! -f "$SSL_CERT" ]] && [[ ! -f "$SSL_KEY" ]]; then
    mkdir -p /opt/sshi/ssl
    openssl req -nodes -x509 -newkey rsa:4096 -keyout /opt/sshi/ssl/key.pem -out /opt/sshi/ssl/cert.pem -days 1095 -subj "/CN=ssh-inscribe"
fi

if [[ ! -f /opt/sshi/conf/users.yml ]] && [[ "$AUTH_TYPE" == "file" ]]; then

FILE_PRINCIPAL=${FILE_PRINCIPAL:-"DefaultPrincipal"}
FILE_PASSWORD_HASH="$(python3 -c "\
import bcrypt
import sys
password = '$FILE_PASSWORD'
hash = bcrypt.hashpw(password.encode('utf8'), bcrypt.gensalt())
hash = hash.decode('utf8')
print (hash)")"
/usr/bin/python3 -c "\
import os
import sys
import jinja2
sys.stdout.write(
    jinja2.Template(sys.stdin.read()
).render(env=os.environ))" </templates/users.yml.j2 > /opt/sshi/conf/users.yml

fi

if [[ ! -f /opt/sshi/config.yml ]]; then

/usr/bin/python3 -c 'import os
import sys
import jinja2
sys.stdout.write(
    jinja2.Template(sys.stdin.read()
).render(env=os.environ))' </templates/config.yml.j2 >/opt/sshi/conf/config.yml

fi

set +a

if [[ "$CA_KEY_GENERATE" == "true" ]] && [[ ! -f "$CA_KEY" ]]; then
    openssl genrsa -out "$CA_KEY" 2048
fi

/usr/local/bin/ssh-inscribe server --config /opt/sshi/conf/config.yml &

if [[ "$CA_KEY_AUTOADD" == "true" ]] && [[ -f "$CA_KEY" ]]; then
    sleep 5
    SSH_AUTH_SOCK="/ssh-agent/ssh_inscribe_agent.sock" ssh-add "$CA_KEY"
fi

while true
do
    sleep 1d
done &

wait $!


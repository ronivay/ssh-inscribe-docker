# ssh-inscribe in docker

This repository contains files to build docker container running ssh-inscribe server.

[ssh-inscribe](https://github.com/aakso/ssh-inscribe) is a CA server/client which helps to manage SSH user certificates. Check more information from the software repository. 

I'm not a maintainer of said software, this repository only wraps available binaries into container and makes initial start easy by providing a set of variables from where the configuration is built. 

# Usage

See more in depth documentation from softwares own repository about usage. This section describes how to use the container image.

Container automates the following:

- creation of server configuration file if none exist
- creation of users authentication file (with single user) if none exist
- creation of certificate/key for server to be used when communicating with clients if none exist
- creation of CA signing key and automatically adding it to server ssh-agent

Repository provides example `env-example` file for configuration variables and an optional `docker-compose.yml` file.

For best outcome you should do the following:

- clone repository
```
git clone https://github.com/ronivay/ssh-inscribe-docker
```
- build container and generate .env config
```
make build-container
make genconfig
```
or with single command:
```
make build
```

- edit configuration variables in `.env` file to match your preference. 
- start container with docker-compose
```
docker-compose up -d
```

Server is now accessible at `https://<docker-host-ip>:8540` ready to be signing certificates

You need to use `--insecure` option with sshi client as the server is running with self-signed certificate by default. 

Optionally you can use images available at [dockerhub](https://hub.docker.com/r/ronivay/ssh-inscribe-docker)

User inside container runs by default with UID/GID 1995, you can change this during build like so:

```
make build SSHI_UID=xxxx SSHI_GID=xxxx
```
Build with specific version of ssh-inscribe
```
make build SSHI_VERSION=x.x.x
```

#### volumes

docker-compose example will bind mount host directory to containers `/opt/sshi` path. This path contains the main configuration file, authentication file and certificate files which you can edit afterwards.

#### additional users

NOTE: automatically created user isn't safe as password is in clear text in .env config and inside container as env var. up to you to decide if this is enough for your usecase

by default, only one user is created to `users.yml` file based on `FILE_USER` and `FILE_PASSWORD` variables. This works fine for single user purpose, but defining multiple users require one to edit `sshi/users.yml` file.

append new users to config with following lines
```
- name: <username>
  password: <password-hash>
  principals:
  - <principal>
  criticalOptions: {}
  extensions:
    permit-pty: ""
    permit-user-rc: ""
    permit-agent-forwarding: ""
    permit-X11-forwarding: ""
```

You can generate password hash inside the container (after it's started) by running
```
docker exec -itd ssh-inscribe ssh-inscribe crypt
```
You'll be prompted for password and server will return the password hash that you should put to users.yml file

#### Variables

`SSL_CERT`

server certificate location inside container

default: /opt/sshi/ssl/cert.pem

`SSL_KEY`

server certificate key location inside container

default: /opt/sshi/ssl/key.pem

`CA_KEY`

certificate signing key location inside container

default: /opt/sshi/ssl/ca-key.pem

`CA_KEY_GENERATE`

certificate signing key will be create automatically if it doesn't exist

note: unsafe as key doesn't have any passphrase or encryption

default: true

`CA_KEY_AUTOADD`

certificate signing key will be added to servers ssh-agent automatically during startup if set to true and key exists

note: unsafe as key needs to be unencrypted

default: true

`AUTH_TYPE`

defines authentication method. available values: file/ldap

default: file

`FILE_USER`

default username for file auth type

default: test

`FILE_PASSWORD`

default password for FILE_USER

default: testpassword

`AUTH_REALM`

realm name presented to user during login

default: default realm

`AUTH_FRIENDLY_NAME`

this will be written to issued certificate keyId

default: default auth

`MAX_CERT_LIFETIME`

the maximum lifetime for certificate that user can request

default: 24h

`DEFAULT_CERT_LIFETIME`

default certificate lifetime if none requested

default: 8h

if `AUTH_TYPE` is set to ldap, following variables are used

`LDAP_SERVER`

ldap connection string.

example: ldaps://ldap-server.tld:636

`LDAP_INSECURE`

if insecure connection to LDAP is allowed

`LDAP_USER_BIND_DN`

authenticated users need to able to bind as themself against LDAP server, no generic user account used here

example: uid={{.UserName}},ou=users,dc=example,dc=com

`LDAP_USER_SEARCH_BASE`

example: ou=users,dc=example,dc=com

`LDAP_USER_SEARCH_FILTER`

example: (uid={{.UserName}})

`LDAP_GROUP_SEARCH_BASE`

example: ou=groups,dc=example,dc=com

`LDAP_GROUP_SEARCH_FILTER`

example: (&(objectClass=posixGroup)(memberUid={{.UserName}}))

`LDAP_SUBJECT_TEMPLATE`

this LDAP field will be shown in SSH cert KeyId

example: {{.User.cn}}

`LDAP_PRINCIPAL_TEMPLATE`

this ldap field will be added as principal to issued SSH cert

example: {{.Group.cn}}

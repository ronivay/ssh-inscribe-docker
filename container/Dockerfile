FROM debian:bullseye-slim

MAINTAINER Roni Väyrynen <roni@vayrynen.info>

ARG SSHI_VERSION
ARG SSHI_UID
ARG SSHI_GID

# install openssh for ssh-agent capability and python for config templates
RUN apt update && \
   apt install -y openssh-client python3-minimal python3-jinja2 python3-bcrypt wget openssl procps

# install sshi client and server binaries
RUN wget -O /usr/local/bin/ssh-inscribe https://github.com/aakso/ssh-inscribe/releases/download/${SSHI_VERSION}/ssh-inscribe-linux-x86_64 && \
    chmod +x /usr/local/bin/ssh-inscribe

# create user
#RUN ${SSHI_UID:-"1995"} ${SSHI_GID:-"1995"} groupadd -g 911 -r sshi && \
#    useradd -m -d /opt/sshi -u 911 -r -g sshi sshi
RUN if [ -z ${SSHI_GID} ]; then groupadd -g 1995 -r sshi; else groupadd -g ${SSHI_GID} -r sshi; fi && \
    if [ -z ${SSHI_UID} ]; then useradd -m -d /opt/sshi -u 1995 -r -g sshi sshi; else \
    useradd -m -d /opt/sshi -u ${SSHI_UID} -r -g sshi sshi; fi

# ssh-inscribe ssh-agent socket will be stored here
RUN mkdir /ssh-agent && chown sshi:sshi /ssh-agent

# create configuration templates
RUN mkdir /templates
ADD conf/config.template.yml.j2 /templates/config.yml.j2
ADD conf/default_users.yml /templates/users.yml.j2

# Copy startup script
ADD run.sh /run.sh
RUN chmod +x /run.sh

# start container as non-privileged user
USER sshi
WORKDIR /opt/sshi

EXPOSE 8540

CMD ["/run.sh"]

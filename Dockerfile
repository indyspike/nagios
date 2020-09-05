#Getting base image from CentOS
FROM debian:stable

LABEL maintainer="indyspike <indy@spikehead.de>" 
ENV container docker
ENV USERN nagiosadmin
ENV UPASS admin
#nagios
RUN apt-get update
RUN apt-get install -y autoconf gcc libc6 make wget unzip apache2 apache2-utils php libgd-dev

RUN cd /tmp;\
    wget -O nagioscore.tar.gz https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.6.tar.gz;\
    tar xzf nagioscore.tar.gz;

RUN cd /tmp/nagios-4.4.6/;\
    ./configure --with-httpd-conf=/etc/apache2/sites-enabled;\
    make all;\
    make install-groups-users;\
    usermod -a -G nagios apache;\
    make install;\
    make install-daemoninit;\
    systemctl enable httpd.service;\
    make install-commandmode;\
    make install-config;\
    make install-webconf;\
    make install-webconf

RUN apt-get install -y autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext

RUN cd /tmp;\
    wget -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.3.3.tar.gz;\
    tar zxf nagios-plugins.tar.gz;

RUN cd /tmp/nagios-plugins-release-2.3.3/;\
    ./tools/setup;\
    ./configure;\
    make;\
    make install;

RUN sed -i '135,148d' /usr/local/nagios/etc/objects/localhost.cfg

RUN mkdir /conf;\
    mv -n /usr/local/nagios/etc/* /conf;\
    rm -rf /usr/local/nagios/etc;\
    ln -s /conf /usr/local/nagios/etc

RUN a2enmod rewrite;\
    a2enmod cgi;

RUN /usr/bin/htpasswd -cb /usr/local/nagios/etc/htpasswd.users ${USERN} ${UPASS}

RUN echo '#!/bin/bash\n\
service apache2 start\n\
service nagios start\n\
tail -f /dev/null\n\
' > /usr/local/nagios/bin/entrypoint.sh && chmod 0755 /usr/local/nagios/bin/entrypoint.sh

EXPOSE 80/tcp
#VOLUME ["/conf"]
ENTRYPOINT ["/usr/local/nagios/bin/entrypoint.sh"]
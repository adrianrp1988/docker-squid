FROM debian:buster-slim as squid_builder

#add backports repo
RUN echo "deb http://deb.debian.org/debian buster-backports main" > /etc/apt/sources.list.d/debian-backports.list

#Install required packages
RUN apt update -y && \
  apt -y install \ 
    build-essential \
    devscripts \
    fakeroot \
    debhelper \
    dh-autoreconf \
    dh-apparmor \
    cdbs \
    smbclient \
    wget \
    tar \
    libcppunit-dev \
    libsasl2-dev \
    libxml2-dev \
    libkrb5-dev \
    libdb-dev \
    libnetfilter-conntrack-dev \
    libexpat1-dev \
    libcap2-dev \
    libldap2-dev \
    libpam0g-dev \
    libgnutls28-dev \
    libssl-dev \
    libdbi-perl \
    libecap3 \
    libecap3-dev \
    libsystemd-dev \
    libtdb-dev \
    checkinstall --no-install-recommends && \
  rm -rf /var/lib/apt/lists/*

#Crearemos los directorios necesarios durante el proceso de compilacion
RUN mkdir -p /usr/share/squid \
 mkdir -p /usr/share/squid/icons \
 mkdir -p /opt/src/icmp/tests \
 mkdir -p /opt/tools/squidclient/tests \
 mkdir -p /opt/tools/tests

WORKDIR /opt
 
#Descargamos y desempaquetamos squid5:
RUN wget -c http://www.squid-cache.org/Versions/v5/squid-5.0.4.tar.gz && tar xfv squid-5.0.4.tar.gz

#Configuramos las opciones basicas que podamos necesitar (se habilitan las opciones para SSL Bump):
RUN /opt/squid-5.0.4/configure --srcdir=/opt/squid-5.0.4/ --prefix=/usr --localstatedir=/var/lib/squid --libexecdir=/usr/lib/squid \
--datadir=/usr/share/squid --sysconfdir=/etc/squid --with-default-user=proxy --with-logdir=/var/log/squid \
--with-open-ssl=/etc/ssl/openssl.cnf --with-openssl --enable-ssl --enable-ssl-crtd --build=x86_64-linux-gnu \
--with-pidfile=/var/run/squid.pid --enable-removal-policies=lru,heap \
--enable-delay-pools --enable-cache-digests --enable-icap-client --enable-ecap --enable-follow-x-forwarded-for \
--with-large-files --with-filedescriptors=65536 \
--enable-auth-basic=DB,fake,getpwnam,LDAP,NCSA,NIS,PAM,POP3,RADIUS,SASL,SMB \
--enable-auth-digest=file,LDAP --enable-auth-negotiate="kerberos,wrapper" --enable-auth-ntlm=fake,SMB_LM \
--enable-linux-netfilter --with-swapdir=/var/spool/squid --enable-useragent-log --enable-htpc \
--infodir=/usr/share/info --mandir=/usr/share/man --includedir=/usr/include --disable-maintainer-mode \
--disable-dependency-tracking --disable-silent-rules --enable-inline --with-aufs-threads=16 \
--enable-storeio=ufs,aufs,diskd,rock --enable-eui --enable-esi --enable-icmp --enable-zph-qos \
--enable-external-acl-helpers="file_userip,kerberos_ldap_group,LDAP_group,session,SQL_session,time_quota,unix_group,wbinfo_group" \
--enable-url-rewrite-helpers="fake" --enable-translation --enable-epoll --enable-snmp --enable-wccpv2 \
--with-aio --with-pthreads --enable-arp --enable-arp-acl --enable-default-err-language=es \
--enable-security-cert-validators="fake" --enable-storeid-rewrite-helpers="file" --disable-arch-native \
--with-build-environment=default 

#Compilamos con multiprocesamiento:
RUN make -j `nproc` && \
 checkinstall \
  --install=no \
  --default \
  --pkgname=squid \
  --provides=squid \
  --pkgversion=5.0.4 \
  --pkgarch=amd64 \
  --pkgrelease=22082020 \
  --pakdir=/opt \
  --maintainer="Adrian Rodriguez" \
  --conflicts="squid3" \
  --requires="libcppunit-dev, libsasl2-dev, libxml2-dev, libkrb5-dev, libdb-dev, libnetfilter-conntrack-dev, libexpat1-dev, libcap2-dev, libldap2-dev, libpam0g-dev, libgnutls28-dev, libssl-dev, libdbi-perl, libecap3, libecap3-dev, libsystemd-dev, libtdb-dev"

FROM debian:buster-slim as squid5
COPY --from=squid_builder /opt/squid_5.0.4-22082020_amd64.deb /opt

RUN apt update && \
    apt install -y /opt/squid_5.0.4-22082020_amd64.deb  \
	wget \
	libltdl7 \
	lsb-base \
	lsb-release --no-install-recommends && \
	rm -rf /var/lib/apt/lists/*

#Copiamos archivos necesarios
COPY squid /etc/init.d/squid
COPY squid.conf /etc/squid/squid.conf
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

ENTRYPOINT ["/sbin/entrypoint.sh"]

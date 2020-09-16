#!/bin/bash

set -e

create_log_dir() {
if [[ -n ${SQUID_LOG_DIR} ]]; then
  mkdir -p ${SQUID_LOG_DIR}
  chmod -R 755 ${SQUID_LOG_DIR}
  chown -R proxy:proxy ${SQUID_LOG_DIR}
else
  mkdir -p /var/log/squid
  chmod -R 755 /var/log/squid
  chown -R proxy:proxy /var/log/squid
fi
}

create_cache_dir() {
if [[ -n ${SQUID_CACHE_DIR} ]]; then
  mkdir -p ${SQUID_CACHE_DIR}
  chown -R proxy:proxy  ${SQUID_CACHE_DIR}
else
  mkdir -p /var/spool/squid
  chmod -R 755 /var/spool/squid
  chown -R proxy:proxy /var/spool/squid
fi
}

create_conf_dir(){
  cp /opt/squid.conf /etc/squid
  chown -R proxy:proxy  /etc/squid/
if [[ -n ${CUSTOM_CONFIG_FILE} ]]; then
  mkdir -p /etc/squid/conf.d
fi
}

setup_user(){
  echo "proxy ALL = NOPASSWD: /usr/sbin/squid" > /etc/sudoers
  chsh -s /bin/bash proxy
}

clean_files(){
  rm /opt/squid.conf
  rm /opt/squid_5.0.4-22082020_amd64.deb
  rm /opt/setup.sh
  rm -rf /var/lib/apt/lists/*
}

create_log_dir
create_cache_dir
create_conf_dir
setup_user
clean_files



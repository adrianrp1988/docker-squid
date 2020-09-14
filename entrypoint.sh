#!/bin/bash
set -e

create_log_dir() {
if [[ -n ${SQUID_LOG_DIR} ]]; then
  mkdir -p ${SQUID_LOG_DIR}
  chmod -R 755 ${SQUID_LOG_DIR}
  chown -R ${SQUID_USER}:${SQUID_USER} ${SQUID_LOG_DIR}
else
  mkdir -p /var/log/squid
  chmod -R 755 /var/log/squid
  chown -R proxy:proxy /var/log/squid
fi
}

create_cache_dir() {
if [[ -n ${SQUID_CACHE_DIR} ]]; then
  mkdir -p ${SQUID_CACHE_DIR}
  chown -R ${SQUID_USER}:${SQUID_USER} ${SQUID_CACHE_DIR}
else
  mkdir -p /var/spool/squid
  chmod -R 755 /var/spool/squid
  chown -R proxy:proxy /var/spool/squid
fi
}

set_service_init_script() {
  chmod +x /etc/init.d/squid
  update-rc.d squid defaults
}

set_basic_confs(){
  if [[ -n ${HTTP_PORT} ]]; then
    sed -i 's/{{HTTP_PORT}}/'${HTTP_PORT}'/g' /etc/squid/squid.conf
  else
    sed -i 's/{{HTTP_PORT}}/3128/g' /etc/squid/squid.conf
  fi

  if [[ -n ${VISIBLE_HOSTNAME} ]]; then
    sed -i 's/{{VISIBLE_HOSTNAME}}/'${VISIBLE_HOSTNAME}'/g' /etc/squid/squid.conf
  else
    sed -i 's/{{VISIBLE_HOSTNAME}}/squid5/g' /etc/squid/squid.conf
  fi

  if [[ -n ${SQUID_USER} ]]; then
    sed -i 's/{{SQUID_USER}}/'${SQUID_USER}'/g' /etc/squid/squid.conf
  else
    sed -i 's/{{SQUID_USER}}/proxy/g' /etc/squid/squid.conf
  fi

  if [[ -n ${SQUID_LOG_DIR} ]]; then
    sed -i 's#{{SQUID_LOG_DIR}}#'${SQUID_LOG_DIR}'#g' /etc/squid/squid.conf
  else
    sed -i 's#{{SQUID_LOG_DIR}}#/var/log/squid#g' /etc/squid/squid.conf
  fi

  if [[ -n ${SQUID_CACHE_DIR} ]]; then
    sed -i 's#{{SQUID_CACHE_DIR}}#'${SQUID_CACHE_DIR}'#g' /etc/squid/squid.conf
  else
    sed -i 's#{{SQUID_CACHE_DIR}}#/var/spool/squid#g' /etc/squid/squid.conf
  fi
}

set_custom_conf_file(){
if [[ -n ${CUSTOM_CONFIG_FILE} ]]; then
  mkdir -p /etc/squid/conf.d
  chmod -R 755 /etc/squid/conf.d
  chown -R proxy:proxy  /etc/squid/conf.d
  chmod -R 755 /etc/squid/conf.d/*
  chown -R proxy:proxy  /etc/squid/conf.d/*
  sed -i 's#{{CUSTOM_CONFIG}}#include /etc/squid/conf.d/'${CUSTOM_CONFIG_FILE}'#g' /etc/squid/squid.conf
else
  sed -i 's/{{CUSTOM_CONFIG}}/#No custom configuration rules added/g' /etc/squid/squid.conf
fi
}
set_service_init_script
create_log_dir
create_cache_dir
set_basic_confs
set_custom_conf_file

# allow arguments to be passed to squid
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == squid || ${1} == $(which squid) ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

# default behaviour is to launch squid
if [[ -z ${1} ]]; then
  if [[ ! -d ${SQUID_CACHE_DIR}/00 ]]; then
    echo "Initializing cache..."
    $(which squid) -N -f /etc/squid/squid.conf -z
  fi
  echo "Starting squid..."
  exec $(which squid) -f /etc/squid/squid.conf -NYCd 1 ${EXTRA_ARGS}
else
  exec "$@"
fi

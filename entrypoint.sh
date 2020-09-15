#!/bin/bash
set -e

setup_logging() {
if [[ -n ${SQUID_LOG_DIR} ]]; then
  mkdir -p ${SQUID_LOG_DIR}
  chmod -R 755 ${SQUID_LOG_DIR}
  chown -R proxy:proxy ${SQUID_LOG_DIR}
  sed -i 's+#Logs+
  access_log stdio:'${SQUID_LOG_DIR}'/access.log
  +g' /etc/squid/squid.conf
  if [[ -n ${SQUID_CACHE_DIR} ]]; then
    sed -i 's+#LogsCache+
    #Cache dir Logs:
    cache_log stdio:'${SQUID_LOG_DIR}'/cache.log
    cache_store_log stdio:'${SQUID_LOG_DIR}'/store.log
    +g' /etc/squid/squid.conf
  else
    sed -i 's+#LogsCache++g' /etc/squid/squid.conf
  fi
else
  mkdir -p /var/log/squid
  chmod -R 755 /var/log/squid
  chown -R proxy:proxy /var/log/squid
  sed -i 's+#LogsCache++g' /etc/squid/squid.conf
  sed -i 's+#Logs++g' /etc/squid/squid.conf
fi
}

setup_cache() {
if [[ -n ${SQUID_CACHE_DIR} ]]; then
  mkdir -p ${SQUID_CACHE_DIR}
  chown -R proxy:proxy  ${SQUID_CACHE_DIR}
  sed -i 's+#Cache+
  cache_effective_user proxy
  cache_effective_group proxy

  # Leave coredumps in the first cache dir
  coredump_dir {{SQUID_CACHE_DIR}}
  +g' /etc/squid/squid.conf
else
  sed -i 's+#Cache++g' /etc/squid/squid.conf
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
}

set_custom_conf_file(){
if [[ -n ${CUSTOM_CONFIG_FILE} ]]; then
  mkdir -p /etc/squid/conf.d
  chmod -R 755 /etc/squid/conf.d
  chown -R proxy:proxy  /etc/squid/conf.d
  chmod -R 755 /etc/squid/conf.d/*
  chown -R proxy:proxy  /etc/squid/conf.d/*
  sed -i 's+#Custom+include /etc/squid/conf.d/'${CUSTOM_CONFIG_FILE}'+g' /etc/squid/squid.conf
else
  sed -i 's/#Custom//g' /etc/squid/squid.conf
fi
}
set_service_init_script
setup_logging
setup_cache
set_basic_confs
set_custom_conf_file

chsh -s /bin/bash proxy

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



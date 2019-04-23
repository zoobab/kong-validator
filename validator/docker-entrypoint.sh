#!/bin/sh
set -e

export KONG_NGINX_DAEMON=on
export KONG_DATABASE=off

has_transparent() {
  echo "$1" | grep -E "[^\s,]+\s+transparent\b" >/dev/null
}

if [[ "$1" == "kong" ]]; then
  PREFIX=${KONG_PREFIX:=/usr/local/kong}

  if [[ "$2" == "docker-start" ]]; then
    shift 2
    kong prepare -p "$PREFIX" "$@"
    
    # workaround for https://github.com/moby/moby/issues/31243
    chmod o+w /proc/self/fd/1 || true
    chmod o+w /proc/self/fd/2 || true

    if [ "$(id -u)" != "0" ]; then
      echo "[1/3] starting kong (with user root)..."
      kong start
      echo "[2/3] Removing configMap..."
      sed  -e "s/configMap:\ |//g" -e "s/^\ \ //g" /mnt/kong.yml > /tmp/kong.yml
      echo "[2/3] checking the config..."
      kong config -c /etc/kong/kong.conf.default parse /tmp/kong.yml
    else
      if [ ! -z ${SET_CAP_NET_RAW} ] \
          || has_transparent "$KONG_STREAM_LISTEN" \
          || has_transparent "$KONG_PROXY_LISTEN" \
          || has_transparent "$KONG_ADMIN_LISTEN";
      then
        setcap cap_net_raw=+ep /usr/local/openresty/nginx/sbin/nginx
      fi
      chown -R kong:0 /usr/local/kong
      echo "[1/3] starting kong (with user kong)..."
      su-exec kong kong start
      echo "[2/3] Removing configMap..."
      su-exec kong sed  -e "s/configMap:\ |//g" -e "s/^\ \ //g" /mnt/kong.yml > /tmp/kong.yml
      chown kong:0 /tmp/kong.yml
      echo "[2/3] checking the config..."
      cp /etc/kong/kong.conf.default /tmp/kong.conf.default
      chown kong:0 /tmp/kong.conf.default
      su-exec kong kong config -c /tmp/kong.conf.default parse /tmp/kong.yml
    fi
  fi
fi

exec "$@"

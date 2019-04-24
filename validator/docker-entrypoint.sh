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
    chmod -f o+w /proc/self/fd/1 || true
    chmod -f o+w /proc/self/fd/2 || true

    if [ "$(id -u)" != "0" ]; then
#      echo "starting kong (with user root)..."
      kong start 2>&1 > /dev/null
      kong config parse /mnt/kong.yml
    else
      if [ ! -z ${SET_CAP_NET_RAW} ] \
          || has_transparent "$KONG_STREAM_LISTEN" \
          || has_transparent "$KONG_PROXY_LISTEN" \
          || has_transparent "$KONG_ADMIN_LISTEN";
      then
        setcap cap_net_raw=+ep /usr/local/openresty/nginx/sbin/nginx
      fi
      chown -R kong:0 /usr/local/kong
#      echo "starting kong (with user kong)..."
      su-exec kong kong start 2>&1 > /dev/null
      su-exec kong kong config parse /mnt/kong.yml
    fi
  fi
fi

exec "$@"

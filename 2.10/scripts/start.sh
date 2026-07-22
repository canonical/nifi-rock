#!/bin/sh
# Entrypoint wrapper. Maps a small set of NIFI_* environment variables onto
# nifi.properties in place, applies single-user credentials if supplied, then
# exec's nifi.sh run.
#
# These variables are optional runtime inputs from a standalone consumer, e.g.
# docker run -e NIFI_WEB_HTTP_PORT=9090 ... -- the same interface the upstream
# apache/nifi image exposes. The set_prop guard makes each one a no-op when unset, so the shipped default survives and
# this wrapper is a no-op under the charm, which sets none of them and pushes
# its own nifi.properties.
#
# There is deliberately no validation here. NiFi enforces the sensitive
# properties key itself: it auto-generates one on a fresh node and refuses to
# start when an existing flow has no key. A shell pre-check could only see
# whether the string is empty, not whether a flow exists, so it would break the
# legitimate fresh-node path while duplicating NiFi's own check with a worse
# error message.
set -e

PROPS="$NIFI_HOME/conf/nifi.properties"

# Written as an if rather than `[ -n "$2" ] && sed ...`: the latter returns 1
# when the variable is unset, and as the function's last command that makes the
# whole call fail, which under set -e exits on the first no-op override.
set_prop() {
  if [ -n "$2" ]; then
    sed -i "s|^$1=.*|$1=$2|" "$PROPS"
  fi
}

set_prop nifi.web.http.host       "$NIFI_WEB_HTTP_HOST"
set_prop nifi.web.http.port       "$NIFI_WEB_HTTP_PORT"
set_prop nifi.web.proxy.host      "$NIFI_WEB_PROXY_HOST"
set_prop nifi.sensitive.props.key "$NIFI_SENSITIVE_PROPS_KEY"

if [ -n "$SINGLE_USER_CREDENTIALS_USERNAME" ] && [ -n "$SINGLE_USER_CREDENTIALS_PASSWORD" ]; then
  "$NIFI_HOME/bin/nifi.sh" set-single-user-credentials \
    "$SINGLE_USER_CREDENTIALS_USERNAME" "$SINGLE_USER_CREDENTIALS_PASSWORD"
fi

exec "$NIFI_HOME/bin/nifi.sh" run

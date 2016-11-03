#!/bin/sh
sudo /usr/share/collectd/wlstats-gatherer.sh "${COLLECTD_HOSTNAME:-localhost}" "${COLLECTD_INTERVAL:-10}"

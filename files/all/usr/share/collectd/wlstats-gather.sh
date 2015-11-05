#!/bin/sh
sudo /usr/share/collectd/wlstats_gatherer.sh "${COLLECTD_HOSTNAME:-localhost}" "${COLLECTD_INTERVAL:-10}"

#!/bin/sh
#
# Simple wireless statistics gatherer for collectd
#
# Description: Simple wireless statistics gatherer for collectd
# Prereqs:     OpenWRT compatible system / wlinfo / wl
# Used via:    Collectd exec plugin type
# Author:      Vladimir Vitkov <vvitkov@linux-bg.org>
#              Petko Bordjukov <bordjukov@gmail.com>
#
# Version:     0.1
# Date:        2015.05.25
#
# Changelog:   2015.05.25 - Initial version
#              2015.11.

# Variable Definition
_HOSTNAME=$1
_PERIOD=10
_PLUGIN='wlstats'

# Binaries
_iwinfo='iwinfo'
_iw='iw'

# main loop
while true ; do
    for _phy in /sys/kernel/debug/ieee80211/phy*; do
        for _netdev in $_phy/netdev:* ; do
            # single cat call
            _metric_group="$(basename ${_phy})-$(basename ${_netdev})"

            for _metric in "num_buffered_multicast" "dtim_count" "num_sta_ps" "num_mcast_sta" "txpower"; do
                echo -e "PUTVAL ${_HOSTNAME}/${_PLUGIN}-${_metric_group}/gauge-${_metric} interval=${_PERIOD} N:$(cat ${_netdev}/${_metric} 2>/dev/null)"
            done

            _stations=`ls -1 ${_netdev}/stations/ | wc -l`
            _vht_stations=`grep -r 'VHT supported' ${_netdev}/stations/*/vht_capa 2>/dev/null | wc -l`
            _ht_stations=`grep -r 'ht supported' ${_netdev}/stations/*/ht_capa 2>/dev/null | wc -l`

            echo -e "PUTVAL ${_HOSTNAME}/${_PLUGIN}-${_metric_group}/gauge-stations interval=${_PERIOD} N:${_stations}"
            echo -e "PUTVAL ${_HOSTNAME}/${_PLUGIN}-${_metric_group}/gauge-ht_stations interval=${_PERIOD} N:${_ht_stations}"
            echo -e "PUTVAL ${_HOSTNAME}/${_PLUGIN}-${_metric_group}/gauge-vht_stations interval=${_PERIOD} N:${_vht_stations}"

            if [ $_stations -gt 0 ]; then
                for _metric in "tx_retry_count" "tx_retry_failed" "rx_dropped" "rx_duplicates" "current_tx_rate" "beacon_loss_count" "last_signal" "connected_time" "inactive_ms" "num_ps_buf_frames"; do
                    _avg_value=`awk 2>/dev/null '{sum+=$1} END { print sum/NR}' ${_netdev}/stations/*/${_metric}`
                    echo -e "PUTVAL ${_HOSTNAME}/${_PLUGIN}-${_metric_group}/gauge-avg_${_metric} interval=${_PERIOD} N:${_avg_value}"
                done
            fi

            if [ -d "${_phy}/ath9k" ]; then
                _interface=$(echo ${_netdev} | sed 's/.*\://')
                ${_iw} dev ${_interface} survey dump | grep -A 5 'in use' > /tmp/${_interface}.survey
                cat /tmp/${_interface}.survey | grep 'channel' | sed 's/ ms$//' | sed $'s/\t//g' | \
                    sed 's/ /_/g' | awk -vhostname="${_HOSTNAME}" \
                                        -vplugin="${_PLUGIN}" \
                                        -vmetric_group="${_metric_group}-ath9k-survey" \
                                        -vinterval="${_PERIOD}" \
                                        -F : \
                                        '{printf "PUTVAL %s/%s-%s/counter-%s interval=%s N:%s\n", hostname, plugin, metric_group, tolower($1), interval, $2}'
            elif [ -d "${_phy}/ath10k" ]; then
                _interface=$(echo ${_netdev} | sed 's/.*\://')
                _interface=$(echo ${_netdev} | sed 's/.*\://')
                ${_iw} dev ${_interface} survey dump | grep -A 3 'in use' > /tmp/${_interface}.survey
                cat /tmp/${_interface}.survey | grep 'channel' | sed 's/ ms$//' | sed $'s/\t//g' | \
                    sed 's/ /_/g' | awk -vhostname="${_HOSTNAME}" \
                                        -vplugin="${_PLUGIN}" \
                                        -vmetric_group="${_metric_group}-ath10k-survey" \
                                        -vinterval="${_PERIOD}" \
                                        -F : \
                                        '{printf "PUTVAL %s/%s-%s/gauge-%s interval=%s N:%s\n", hostname, plugin, metric_group, tolower($1), interval, $2}'
            fi

        done

        _metric_group="$(basename ${_phy})"

        if [ -d "${_phy}/ath9k" ]; then
            cat $_phy/ath9k/recv | \
                sed 's/^ *\(.*\w\) *: *\([^ ]\)*$/\1:\2/g' | \
                sed 's/ /_/' | awk -vhostname="${_HOSTNAME}" \
                                   -vplugin="${_PLUGIN}" \
                                   -vmetric_group="${_metric_group}-ath9k-recv" \
                                   -vinterval="${_PERIOD}" \
                                   -F : \
                                   '{printf "PUTVAL %s/%s-%s/counter-%s interval=%s N:%s\n", hostname, plugin, metric_group, tolower($1), interval, $2}'

            cat $_phy/ath9k/phy_err | \
                sed 's/^ *\(.*\w\) *: *\([^ ]\)*$/\1:\2/g' | \
                sed 's/ /_/' | awk -vhostname="${_HOSTNAME}" \
                                   -vplugin="${_PLUGIN}" \
                                   -vmetric_group="${_metric_group}-ath9k-phy_err" \
                                   -vinterval="${_PERIOD}" \
                                   -F : \
                                   '{printf "PUTVAL %s/%s-%s/counter-%s interval=%s N:%s\n", hostname, plugin, metric_group, tolower($1), interval, $2}'

            cat $_phy/ath9k/dfs_stats | grep '^ ' | \
                sed 's/^ *\(.*\w\) *: *\([^ ]\)*$/\1:\2/g' | \
                sed 's/ /_/g' | \
                sed 's/\.//g' | awk -vhostname="${_HOSTNAME}" \
                                    -vplugin="${_PLUGIN}" \
                                    -vmetric_group="${_metric_group}-ath9k-dfs_stats" \
                                    -vinterval="${_PERIOD}" \
                                    -F : \
                                   '{printf "PUTVAL %s/%s-%s/counter-%s interval=%s N:%s\n", hostname, plugin, metric_group, tolower($1), interval, $2}'

            for _queue in $_phy/ath9k/qlen*; do
                echo -e "PUTVAL ${_HOSTNAME}/${_PLUGIN}-${_metric_group}-ath9k/gauge-$(basename $_queue) interval=${_PERIOD} N:$(cat ${_queue})"
            done

        elif [ -d "${_phy}/ath10k" ]; then
            cat $_phy/ath10k/dfs_stats | grep ':.*[0-9]$' | \
                sed 's/^ *\(.*\w\) *: *\([^ ]\)*$/\1:\2/g' | \
                sed 's/ /_/g' | \
                sed 's/\.//g' | awk -vhostname="${_HOSTNAME}" \
                                    -vplugin="${_PLUGIN}" \
                                    -vmetric_group="${_metric_group}-ath10k-dfs_stats" \
                                    -vinterval="${_PERIOD}" \
                                    -F : \
                                   '{printf "PUTVAL %s/%s-%s/counter-%s interval=%s N:%s\n", hostname, plugin, metric_group, tolower($1), interval, $2}'
        fi

        for _metric in ${_phy}/statistics/* ; do
            _metric_name="$(basename ${_metric})"
	    echo -e "PUTVAL ${_HOSTNAME}/${_PLUGIN}-${_metric_group}-statistics/counter-$(echo ${_metric_name}) N:$(cat ${_metric} 2>/dev/null)"
	done

    done

    sleep ${_PERIOD}
done

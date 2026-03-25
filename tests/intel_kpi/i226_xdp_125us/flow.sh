#!/bin/bash
#
# Copyright (C) 2026 Linutronix GmbH
# Author Kurt Kanzenbach <kurt@linutronix.de>
#
# SPDX-License-Identifier: BSD-2-Clause
#
# Setup Tx and Rx traffic flows for Intel i226 NIC(s) KPI testing.
#

set -e

source ../../lib/common.sh
source ../../lib/igc.sh

#
# Command line arguments.
#
INTERFACE=$1
CYCLETIME_NS=$2
BASETIME=$3

[ -z $INTERFACE ] && INTERFACE="enp3s0"                          # default: enp3s0
[ -z $CYCLETIME_NS ] && CYCLETIME_NS="125000"                    # default: 125us
[ -z $BASETIME ] && BASETIME=$(date '+%s000000000' -d '-30 sec') # default: now - 30s

load_kernel_modules

igc_start "${INTERFACE}"
ethtool -C ${INTERFACE} rx-usecs 0

#
# Split traffic between TSN High Streams and everything else.
#
ENTRY1_NS="75000" # Everything else
ENTRY2_NS="50000" # TSN High Streams

#
# Tx Assignment with Qbv and full hardware offload.
#
# PCP 6 - Tx Q 1 - TSN High Streams
# PCP X - Tx Q 0 - Everything else
#
tc qdisc replace dev ${INTERFACE} handle 100 parent root taprio num_tc 2 \
  map 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 \
  queues 1@0 1@1 \
  base-time ${BASETIME} \
  sched-entry S 0x03 ${ENTRY1_NS} \
  sched-entry S 0x02 ${ENTRY2_NS} \
  flags 0x02

#
# Rx Queues Assignment.
#
# PCP 6 - Rx Q 1 - TSN High Streams
# PCP X - Rx Q 0 - Everything else
RXQUEUES=(0 1 0 0 0 0 0 0 0 0)
igc_rx_queues_assign "${INTERFACE}" RXQUEUES

setup_irqs "${INTERFACE}"

# Find IRQ number for the TxRx-1 queue and set its affinity to CPU 1
IRQ_NUM=$(grep "${INTERFACE}-TxRx-1" /proc/interrupts | awk '{print $1}' | sed 's/://')
if [ -n "$IRQ_NUM" ]; then
    echo "Setting IRQ ${IRQ_NUM} (${INTERFACE}-TxRx-1) affinity to CPU 1"
    echo 1 > /proc/irq/${IRQ_NUM}/smp_affinity_list
else
    echo "Warning: Could not find IRQ for ${INTERFACE}-TxRx-1"
fi

exit 0

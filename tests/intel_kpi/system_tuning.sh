#!/bin/bash
#
# Copyright (C) 2026 Intel Corporation
# Author Song Yoong Siang <yoong.siang.song@intel.com>
#
# SPDX-License-Identifier: BSD-2-Clause
#
# System performance tuning for real-time KPI testing.
#

set -e

echo "Configuring CPU 1 for performance mode"
cpupower -c 1 idle-set -d 0
cpupower -c 1 idle-set -d 1
cpupower -c 1 idle-set -d 2
cpupower -c 1 idle-set -d 3
cpupower -c 1 frequency-set --min 2900M --max 2900M -g performance
tuna isolate --cpus=1

# Get total number of CPUs and configure all except CPU 1 for powersave
TOTAL_CPUS=$(nproc --all)
echo "Configuring ${TOTAL_CPUS} CPUs for powersave mode (excluding CPU 1)"
for ((cpu = 0; cpu < TOTAL_CPUS; cpu++)); do
  if [ "$cpu" -ne 1 ]; then
    BASE_FREQ_PATH="/sys/devices/system/cpu/cpu${cpu}/cpufreq/base_frequency"
    if [ -r "$BASE_FREQ_PATH" ]; then
      BASE_FREQ_KHZ=$(cat "$BASE_FREQ_PATH")
      BASE_FREQ_MHZ=$((BASE_FREQ_KHZ / 1000))
      cpupower -c "$cpu" frequency-set --max "${BASE_FREQ_MHZ}M" -g powersave
    else
      echo "Warning: Could not read ${BASE_FREQ_PATH}, skipping CPU ${cpu}"
    fi
  fi
done

# Find IRQ number for the TxRx-1 queue and set its affinity to CPU 1
INTERFACE="enp85s0"
IRQ_NUM=$(grep "${INTERFACE}-TxRx-1" /proc/interrupts | awk '{print $1}' | sed 's/://')
if [ -n "$IRQ_NUM" ]; then
  echo "Setting IRQ ${IRQ_NUM} (${INTERFACE}-TxRx-1) affinity to CPU 1"
  echo 1 >/proc/irq/${IRQ_NUM}/smp_affinity_list
else
  echo "Warning: Could not find IRQ for ${INTERFACE}-TxRx-1"
fi

echo "Ring/Uncore Frequency fixed"
wrmsr -p 1 0x620 0x2424

echo "L3 cache isolation"
wrmsr 0xc91 0xfc0
wrmsr 0xc90 0x03f
wrmsr -p 1 0xc8f 0x100000000

exit 0

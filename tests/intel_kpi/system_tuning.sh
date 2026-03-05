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
cpupower -c 1 frequency-set --min 3100M --max 3100M -g performance
tuna --cpus=1 --isolate

# Get total number of CPUs and configure all except CPU 1 for powersave
TOTAL_CPUS=$(nproc)
echo "Configuring ${TOTAL_CPUS} CPUs for powersave mode (excluding CPU 1)"
for ((cpu=0; cpu<TOTAL_CPUS; cpu++)); do
    if [ $cpu -ne 1 ]; then
        cpupower -c $cpu frequency-set --min 400M --max 2100M -g powersave
    fi
done

echo "Fix ptp4l and phc2sys CPU affinity to CPU 0"
sudo taskset -cp 0 $(pgrep ptp4l)
sudo taskset -cp 0 $(pgrep phc2sys)

echo "Ring/Uncore Frequency fixed"
wrmsr -p 1 0x620 0x2424

echo "L3 cache isolation"
wrmsr 0xc91 0xfc0
wrmsr 0xc90 0x03f
wrmsr -p 1 0xc8f 0x100000000

exit 0

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

cpupower -c 1 idle-set -d 0
cpupower -c 1 idle-set -d 1
cpupower -c 1 idle-set -d 2
cpupower -c 1 idle-set -d 3
cpupower -c 1 frequency-set --min 3100M --max 3100M -g performance
tuna --cpus=1 --isolate
cpupower -c 0 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 2 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 3 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 4 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 5 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 6 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 7 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 8 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 9 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 10 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 11 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 12 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 13 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 14 frequency-set --min 400M --max 2100M -g powersave
cpupower -c 15 frequency-set --min 400M --max 2100M -g powersave

echo "setting 620 MSR:"
rdmsr -p 1 0x620
wrmsr -p 1 0x620 0x2424
rdmsr -p 1 0x620

# Set CPU affinity to CPU 0
sudo taskset -cp 0 $(pgrep ptp4l)
sudo taskset -cp 0 $(pgrep phc2sys)

exit 0

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
cpupower -c 2 idle-set -d 0
cpupower -c 2 idle-set -d 1
cpupower -c 2 idle-set -d 2
cpupower -c 2 idle-set -d 3
cpupower -c 2 frequency-set --min 3100M --max 3100M -g performance
tuna --cpus=2 --isolate

echo "setting 620 MSR:"
rdmsr -p 1 0x620
wrmsr -p 1 0x620 0x2424
rdmsr -p 1 0x620

exit 0

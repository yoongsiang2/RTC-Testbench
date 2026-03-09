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

sudo cpupower -c 1 idle-set -d 0
sudo cpupower -c 1 idle-set -d 1
sudo cpupower -c 1 idle-set -d 2
sudo cpupower -c 1 idle-set -d 3
sudo cpupower -c 1 frequency-set --min 4200M --max 4200M -g performance
sudo tuna --cpus=1 --isolate

# sudo bash -c 'echo -1 > /proc/sys/kernel/sched_rt_runtime_us'

echo "setting 620 MSR:"
rdmsr -p 1 0x620
wrmsr -p 1 0x620 0x2424
rdmsr -p 1 0x620

exit 0

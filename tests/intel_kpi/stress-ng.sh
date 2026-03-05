#!/bin/bash
#

set -e

echo Stress CPU2-8
stress-ng --taskset 2-8 --cpu 7 --cpu-load 100 -t 0 > /dev/null &

sleep 1
ps -eLFc | head -n 1 ; ps -eLFc | grep stress-ng ; date

exit 0

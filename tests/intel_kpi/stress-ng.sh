#!/bin/bash
#

set -e

echo Stress CPU3-8
stress-ng --taskset 3-8 --cpu 6 --cpu-load 100 -t 0 > /dev/null &

sleep 1
ps -eLFc | head -n 1 ; ps -eLFc | grep stress-ng ; date

exit 0

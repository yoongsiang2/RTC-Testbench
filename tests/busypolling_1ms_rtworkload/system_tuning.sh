#!/bin/bash
#

set -e

echo "Disable idle states and fix CPU frequency for CPU 1 and 2"
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

echo "Set to powersave for the rest of the cores"
cpupower -c 0 frequency-set --min 400M --max 2100M -g powersave
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

echo "Ring/Uncore Frequency fixed"
wrmsr -p 1 0x620 0x2424

echo "L3 cache isolation"
wrmsr 0xc91 0xfc0
wrmsr 0xc90 0x03f
wrmsr -p 1 0xc8f 0x100000000
wrmsr -p 2 0xc8f 0x100000000

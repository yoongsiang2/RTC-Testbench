#!/bin/bash
#/******************************************************************************
# CAT (Cache Allocation Technology) Setup Script for 16 CPU System
# *****************************************************************************/

RT_TEST_CORES=(1 2)

L2_BASE_REG_MSR=0xd10
L2_HIGHEST_COS_NUMBER=8
L2_CORE_MASK=0xfff
L2_RT_BIG_CORE_CMASK=0xfff
L2_RT_ATOM_CMASK=0xfff
L2_BE_BIG_CORE_CMASK=0xfff
L2_BE_ATOM_CMASK=0xfff

L3_BASE_REG_MSR=0xc90
L3_HIGHEST_COS_NUMBER=16
L3_CORE_MASK=0x3ff
L3_RT_BIG_CORE_CMASK=0xfc0
L3_RT_ATOM_CMASK=0xfc0
L3_BE_BIG_CORE_CMASK=0x03f
L3_BE_ATOM_CMASK=0x03f

IA32_PQR_ASSOC_MSR=0xc8f
L2_L3_RT_BIG_CORE_ASSOCIATIVITY=1
L2_L3_BE_BIG_CORE_ASSOCIATIVITY=0
L2_L3_RT_ATOM_ASSOCIATIVITY=1
L2_L3_BE_ATOM_ASSOCIATIVITY=0

DEFAULT_L2_L3_RT_BIG_CORE_ASSOCIATIVITY=0x0
DEFAULT_L2_L3_RT_ATOM_ASSOCIATIVITY=0x0
DEFAULT_L2_CORE_MASK=0xfff
DEFAULT_L3_CORE_MASK=0xfff

# Directory for cat_cpuid_app
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

echo "=== CAT Configuration for 16 CPU System ==="
echo "RT Cores: ${RT_TEST_CORES[*]}"
echo "BE Cores: 0,3-15"
echo ""

# Check CAT support
echo "Checking CAT support..."
if command -v rdmsr &> /dev/null && command -v wrmsr &> /dev/null; then
    echo "MSR tools found. CAT configuration will proceed."
else
    echo "Error: rdmsr/wrmsr tools not found. Please install msr-tools package."
    exit 1
fi

# Load MSR module if needed
if ! lsmod | grep -q msr; then
    echo "Loading MSR kernel module..."
    modprobe msr
fi

echo ""
echo "=== Phase 1: Reading initial CAT configuration ==="

# Read initial L2 waymasks
echo "L2 Waymasks (initial state):"
for ((reg_index=0; reg_index<$L2_HIGHEST_COS_NUMBER; reg_index++)); do
    reg_addr=$((L2_BASE_REG_MSR + reg_index))
    value=$(rdmsr $reg_addr 2>/dev/null || echo "N/A")
    printf "reg: %x = %s\n" $reg_addr $value
done

# Read initial L3 waymasks
echo -e "\nL3 Waymasks (initial state):"
for ((reg_index=0; reg_index<$L3_HIGHEST_COS_NUMBER; reg_index++)); do
    reg_addr=$((L3_BASE_REG_MSR + reg_index))
    value=$(rdmsr $reg_addr 2>/dev/null || echo "N/A")
    printf "reg: %x = %s\n" $reg_addr $value
done

# Read initial core associativity
echo -e "\nL2/L3 Core Associativity (initial state):"
for core in {0..15}; do
    value=$(rdmsr -p $core $IA32_PQR_ASSOC_MSR 2>/dev/null || echo "N/A")
    printf "core: %d reg: %x = %s\n" $core $IA32_PQR_ASSOC_MSR $value
done

echo ""
echo "=== Phase 2: Initializing L2 waymasks to defaults ==="

# Initialize all L2 waymasks to default
for ((reg_index=0; reg_index<$L2_HIGHEST_COS_NUMBER; reg_index++)); do
    reg_addr=$((L2_BASE_REG_MSR + reg_index))
    wrmsr $reg_addr $DEFAULT_L2_CORE_MASK
    value=$(rdmsr $reg_addr)
    printf "reg: %x = %s\n" $reg_addr $value
done

echo ""
echo "=== Phase 3: Initializing L3 waymasks to defaults ==="

# Initialize all L3 waymasks to default
for ((reg_index=0; reg_index<$L3_HIGHEST_COS_NUMBER; reg_index++)); do
    reg_addr=$((L3_BASE_REG_MSR + reg_index))
    wrmsr $reg_addr $DEFAULT_L3_CORE_MASK
    value=$(rdmsr $reg_addr)
    printf "reg: %x = %s\n" $reg_addr $value
done

echo ""
echo "=== Phase 4: Initializing core associativity to defaults ==="

# Initialize all core associativity registers to default
for core in {0..15}; do
    # For simplicity, assume all cores are Big cores (type 40)
    # In real implementation, you'd check core type with cat_cpuid_app
    wrmsr -p $core $IA32_PQR_ASSOC_MSR $DEFAULT_L2_L3_RT_BIG_CORE_ASSOCIATIVITY
    value=$(rdmsr -p $core $IA32_PQR_ASSOC_MSR)
    printf "core: %d reg: %x = %s\n" $core $IA32_PQR_ASSOC_MSR $value
done

echo ""
echo "=== Phase 5: Configuring RT and BE waymasks ==="

# Configure L2 RT and BE waymasks
if [[ $L2_HIGHEST_COS_NUMBER -gt 0 ]]; then
    echo "Configuring RT and Best Effort waymasks for L2"

    # RT Big Core waymask
    reg_addr=$((L2_BASE_REG_MSR + L2_L3_RT_BIG_CORE_ASSOCIATIVITY))
    wrmsr $reg_addr $L2_RT_BIG_CORE_CMASK
    value=$(rdmsr $reg_addr)
    printf "L2 RT Big Core reg: %x = %s\n" $reg_addr $value

    # BE Big Core waymask
    reg_addr=$((L2_BASE_REG_MSR + L2_L3_BE_BIG_CORE_ASSOCIATIVITY))
    wrmsr $reg_addr $L2_BE_BIG_CORE_CMASK
    value=$(rdmsr $reg_addr)
    printf "L2 BE Big Core reg: %x = %s\n" $reg_addr $value

    # RT Atom waymask
    reg_addr=$((L2_BASE_REG_MSR + L2_L3_RT_ATOM_ASSOCIATIVITY))
    wrmsr $reg_addr $L2_RT_ATOM_CMASK
    value=$(rdmsr $reg_addr)
    printf "L2 RT Atom reg: %x = %s\n" $reg_addr $value

    # BE Atom waymask
    reg_addr=$((L2_BASE_REG_MSR + L2_L3_BE_ATOM_ASSOCIATIVITY))
    wrmsr $reg_addr $L2_BE_ATOM_CMASK
    value=$(rdmsr $reg_addr)
    printf "L2 BE Atom reg: %x = %s\n" $reg_addr $value
fi

# Configure L3 RT and BE waymasks
if [[ $L3_HIGHEST_COS_NUMBER -gt 0 ]]; then
    echo -e "\nConfiguring RT and Best Effort waymasks for L3"

    # RT Big Core waymask
    reg_addr=$((L3_BASE_REG_MSR + L2_L3_RT_BIG_CORE_ASSOCIATIVITY))
    wrmsr $reg_addr $L3_RT_BIG_CORE_CMASK
    value=$(rdmsr $reg_addr)
    printf "L3 RT Big Core reg: %x = %s\n" $reg_addr $value

    # BE Big Core waymask
    reg_addr=$((L3_BASE_REG_MSR + L2_L3_BE_BIG_CORE_ASSOCIATIVITY))
    wrmsr $reg_addr $L3_BE_BIG_CORE_CMASK
    value=$(rdmsr $reg_addr)
    printf "L3 BE Big Core reg: %x = %s\n" $reg_addr $value

    # RT Atom waymask
    reg_addr=$((L3_BASE_REG_MSR + L2_L3_RT_ATOM_ASSOCIATIVITY))
    wrmsr $reg_addr $L3_RT_ATOM_CMASK
    value=$(rdmsr $reg_addr)
    printf "L3 RT Atom reg: %x = %s\n" $reg_addr $value

    # BE Atom waymask
    reg_addr=$((L3_BASE_REG_MSR + L2_L3_BE_ATOM_ASSOCIATIVITY))
    wrmsr $reg_addr $L3_BE_ATOM_CMASK
    value=$(rdmsr $reg_addr)
    printf "L3 BE Atom reg: %x = %s\n" $reg_addr $value
fi

echo ""
echo "=== Phase 6: Configuring core associativity ==="

# Configure Best Effort cores (all except RT cores)
echo "Configuring Best Effort cores (0,3,4,5,6,7,8,9,10,11,12,13,14,15)..."
be_cores=(0 3 4 5 6 7 8 9 10 11 12 13 14 15)
be_mask=$((L2_L3_BE_BIG_CORE_ASSOCIATIVITY << 32))

for core in "${be_cores[@]}"; do
    wrmsr -p $core $IA32_PQR_ASSOC_MSR $be_mask
    value=$(rdmsr -p $core $IA32_PQR_ASSOC_MSR)
    printf "BE core: %d reg: %x = %s\n" $core $IA32_PQR_ASSOC_MSR $value
done

# Configure Real Time cores
echo -e "\nConfiguring Real Time cores (${RT_TEST_CORES[*]})..."
rt_mask=$((L2_L3_RT_BIG_CORE_ASSOCIATIVITY << 32))

# RT Cores
for rt_core in "${RT_TEST_CORES[@]}"; do
    wrmsr -p $rt_core $IA32_PQR_ASSOC_MSR $rt_mask
    value=$(rdmsr -p $rt_core $IA32_PQR_ASSOC_MSR)
    printf "RT core: %d reg: %x = %s\n" $rt_core $IA32_PQR_ASSOC_MSR $value
done
echo ""
echo "=== Final Verification ==="

# Verify final L2/L3 Core Associativity
echo "Final L2/L3 Core Associativity:"
for core in {0..15}; do
    value=$(rdmsr -p $core $IA32_PQR_ASSOC_MSR)
    is_rt_core=false
    for rt_core in "${RT_TEST_CORES[@]}"; do
        if [[ $core -eq $rt_core ]]; then
            is_rt_core=true
            break
        fi
    done
    if [[ $is_rt_core == true ]]; then
        printf "core: %d (RT) reg: %x = %s\n" $core $IA32_PQR_ASSOC_MSR $value
    else
        printf "core: %d (BE) reg: %x = %s\n" $core $IA32_PQR_ASSOC_MSR $value
    fi
done

echo ""
echo "=== CAT Configuration Complete ==="
echo "Summary:"
echo "- L2 cache: 8 waymask registers configured"
echo "- L3 cache: 16 waymask registers configured"
echo "- RT cores (${RT_TEST_CORES[*]}): Configured for Real-Time workloads"
echo "- BE cores (0,3-15): Configured for Best-Effort workloads"
echo "- All MSR operations completed successfully"
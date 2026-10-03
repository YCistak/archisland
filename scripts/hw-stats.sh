#!/usr/bin/env bash

# CPU usage
read -r _ a b c idle _ < /proc/stat
prev_total=$((a + b + c + idle))
prev_idle=$idle

# Read meminfo
mem_total_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
mem_avail_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
mem_used_gb=$(awk "BEGIN {printf \"%.1f\", ($mem_total_kb - $mem_avail_kb) / 1048576}")
mem_total_gb=$(awk "BEGIN {printf \"%.1f\", $mem_total_kb / 1048576}")
mem_percent=$(( (mem_total_kb - mem_avail_kb) * 100 / mem_total_kb ))

# CPU temp
temp=0
if [ -f /sys/class/thermal/thermal_zone1/temp ]; then
    temp=$(( $(cat /sys/class/thermal/thermal_zone1/temp) / 1000 ))
elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    temp=$(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
fi

# GPU (RTX 4060)
gpu_info=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null || echo "0, 0, 0, 0")
IFS=',' read -r gpu_util gpu_temp gpu_mem_used gpu_mem_total <<< "$gpu_info"
gpu_util=$(echo "$gpu_util" | tr -d ' ')
gpu_temp=$(echo "$gpu_temp" | tr -d ' ')
gpu_mem_used=$(echo "$gpu_mem_used" | tr -d ' ')
gpu_mem_total=$(echo "$gpu_mem_total" | tr -d ' ')

sleep 0.1
read -r _ a b c idle _ < /proc/stat
total=$((a + b + c + idle))
diff_total=$((total - prev_total))
diff_idle=$((idle - prev_idle))
cpu_percent=$(( (diff_total - diff_idle) * 100 / (diff_total > 0 ? diff_total : 1) ))

cat <<JSON
{"cpu":$cpu_percent,"temp":$temp,"ram_used":"$mem_used_gb","ram_total":"$mem_total_gb","ram_percent":$mem_percent,"gpu_util":$gpu_util,"gpu_temp":$gpu_temp,"gpu_mem_used":$gpu_mem_used,"gpu_mem_total":$gpu_mem_total}
JSON

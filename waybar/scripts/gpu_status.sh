#!/bin/bash

# GPU monitoring script for Waybar
# Supports AMD GPUs via radeontop and sysfs

get_amd_gpu_info() {
    local gpu_usage=""
    local gpu_temp=""
    local gpu_mem=""
    local gpu_freq=""
    
    # Method 1: Try to get usage from sysfs (fastest)
    if [ -f "/sys/class/drm/card1/device/gpu_busy_percent" ]; then
        gpu_usage=$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null)
    fi
    
    # Method 2: Get temperature from sysfs
    if [ -d "/sys/class/drm/card1/device/hwmon" ]; then
        for hwmon in /sys/class/drm/card1/device/hwmon/hwmon*; do
            if [ -f "$hwmon/temp1_input" ]; then
                local temp_millic=$(cat "$hwmon/temp1_input" 2>/dev/null)
                if [ -n "$temp_millic" ]; then
                    gpu_temp=$((temp_millic / 1000))
                    break
                fi
            fi
        done
    fi
    
    # Method 3: Get memory usage from radeontop (if available and needed)
    if command -v radeontop >/dev/null 2>&1; then
        # Use radeontop for more detailed info if sysfs doesn't provide everything
        local radeontop_output=$(timeout 2s radeontop -d - -l 1 2>/dev/null | tail -n 1)
        if [ -n "$radeontop_output" ]; then
            # Parse radeontop output: "gpu 15.38%, ee 0.00%, vgt 0.00%, ta 0.00%, sx 0.00%, sh 0.00%, spi 0.00%, sc 0.00%, pa 0.00%, db 0.00%, cb 0.00%, vram 23.45% 576mb, gtt 1.56% 64mb"
            if [ -z "$gpu_usage" ]; then
                gpu_usage=$(echo "$radeontop_output" | grep -o 'gpu [0-9.]*%' | grep -o '[0-9.]*')
            fi
            gpu_mem=$(echo "$radeontop_output" | grep -o 'vram [0-9.]*%' | grep -o '[0-9.]*')
            gpu_freq=$(cat /sys/class/drm/card1/device/pp_dpm_sclk 2>/dev/null | grep '\*' | awk '{print $2}' | cut -d'M' -f1)
        fi
    fi
    
    # Format output
    local text=""
    local tooltip=""
    
    # Main display text
    if [ -n "$gpu_usage" ]; then
        local usage_int=$(printf "%.0f" "$gpu_usage")
        text="${usage_int}"
        tooltip+="Usage: ${usage_int}%\n"
    else
        text="N/A"
        tooltip+="Usage: N/A\n"
    fi
    
    # Add temperature if available
    if [ -n "$gpu_temp" ]; then
        tooltip+="Temperature: ${gpu_temp}°C\n"
    fi
    
    # Add memory if available
    if [ -n "$gpu_mem" ]; then
        tooltip+="VRAM: ${gpu_mem}%\n"
    fi
    
    # Add frequency if available
    if [ -n "$gpu_freq" ]; then
        tooltip+="Frequency: ${gpu_freq}MHz"
    fi
    
    # Determine CSS class based on usage
    local class="gpu"
    if [ -n "$gpu_usage" ]; then
        local usage_int=$(printf "%.0f" "$gpu_usage")
        if [ "$usage_int" -gt 80 ]; then
            class="gpu-high"
        elif [ "$usage_int" -gt 50 ]; then
            class="gpu-medium"
        else
            class="gpu-low"
        fi
    fi
    
    # Output JSON for Waybar
    printf '{"text":"%s","tooltip":"%s","class":"%s","percentage": %d}\n' "$text" "$tooltip" "$class" $usage_int
}

# Main execution
if lspci | grep -qi "amd\|radeon"; then
    # AMD GPU detected
    get_amd_gpu_info
else
    # No discrete GPU or unsupported
    echo '{"text":"N/A","tooltip":"No supported GPU detected","class":"gpu"}'
fi
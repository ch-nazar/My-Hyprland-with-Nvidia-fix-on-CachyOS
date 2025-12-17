#!/bin/bash

# Лог-файл, щоб ми бачили, що відбувається (читати командою: cat /tmp/gpu-log.txt)
LOG="/tmp/gpu-log.txt"
exec > >(tee -a $LOG) 2>&1

echo "=== GPU Script Started: $(date) ==="

# Чекаємо 20 секунд, щоб Hyprland точно завантажився
sleep 20

GPU="0000:01:00.0"

# 1. Зачистка (вбиваємо все, що чіпає NVIDIA)
echo "Stopping services..."
systemctl stop nvidia-persistenced
fuser -k -9 /dev/nvidia0
fuser -k -9 /dev/nvidiactl
fuser -k -9 /dev/nvidia-modeset

# 2. Вивантажуємо драйвер
echo "Unloading drivers..."
modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia

# Перевірка: чи вивантажились модулі?
if lsmod | grep -q "nvidia"; then
    echo "CRITICAL: Modules still loaded! Aborting to prevent Zombie state."
    exit 1
fi

# 3. Вмикаємо режим сну
echo "Enabling auto power control..."
if [ -e "/sys/bus/pci/devices/$GPU/power/control" ]; then
    echo auto > "/sys/bus/pci/devices/$GPU/power/control"
fi

# 4. ЦИКЛ ПЕРЕВІРКИ (Чекаємо D3cold)
echo "Waiting for D3cold state..."
SAFE_TO_REMOVE=false

for i in {1..15}; do
    STATE=$(cat /sys/bus/pci/devices/$GPU/power_state 2>/dev/null)
    echo "Attempt $i: State is $STATE"
    
    if [ "$STATE" == "D3cold" ]; then
        SAFE_TO_REMOVE=true
        break
    fi
    sleep 1
done

# 5. МОМЕНТ ІСТИНИ
if [ "$SAFE_TO_REMOVE" = true ]; then
    echo "SUCCESS: GPU is sleeping. Removing device safely."
    # Видаляємо супутні пристрої
    for dev in 0000:01:00.1 0000:01:00.2 0000:01:00.3; do
         [ -e "/sys/bus/pci/devices/$dev/remove" ] && echo 1 > "/sys/bus/pci/devices/$dev/remove"
    done
    # Видаляємо головний GPU
    echo 1 > "/sys/bus/pci/devices/$GPU/remove"
    echo "Done. Battery should be low."
else
    echo "FAIL: GPU refused to sleep (State: $STATE). SKIPPING REMOVAL to avoid high power usage."
    echo "Please check usage manually."
fi

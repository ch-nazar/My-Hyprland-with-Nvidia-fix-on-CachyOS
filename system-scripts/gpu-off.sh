#!/bin/bash

# Лог
LOG="/tmp/gpu-log.txt"
exec > >(tee -a $LOG) 2>&1
echo "=== GPU Power Management Started: $(date) ==="

# Чекаємо трохи, щоб система заспокоїлась
sleep 15

GPU="0000:01:00.0"

# 1. Зупиняємо persistenced (він не дає карті спати)
systemctl stop nvidia-persistenced

# 2. Просто кажемо драйверу: "Можеш спати"
# Ми НЕ вивантажуємо драйвер. Ми НЕ видаляємо пристрій.
if [ -e "/sys/bus/pci/devices/$GPU/power/control" ]; then
    echo "Setting power control to auto..."
    echo auto > "/sys/bus/pci/devices/$GPU/power/control"
else
    echo "ERROR: GPU not found."
fi

# 3. Перевірка
echo "Waiting for driver to suspend GPU..."
for i in {1..10}; do
    STATE=$(cat /sys/bus/pci/devices/$GPU/power_state 2>/dev/null)
    echo "State: $STATE"
    if [ "$STATE" == "D3cold" ]; then
        echo "SUCCESS: GPU is sleeping (D3cold). Driver is handling it."
        exit 0
    fi
    sleep 2
done

echo "Done."

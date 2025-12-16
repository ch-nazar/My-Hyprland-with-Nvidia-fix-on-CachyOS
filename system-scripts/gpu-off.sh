#!/bin/bash
# Чекаємо стабілізації системи
sleep 15

GPU="0000:01:00.0"

# 1. Зачистка процесів
fuser -k -9 /dev/nvidia0
fuser -k -9 /dev/nvidiactl
fuser -k -9 /dev/nvidia-modeset
systemctl stop nvidia-persistenced

# 2. Вивантаження драйверів (це працює)
modprobe -r nvidia_drm
modprobe -r nvidia_modeset
modprobe -r nvidia_uvm
modprobe -r nvidia

# 3. Видаляємо супутні пристрої (Audio/USB)
for dev in 0000:01:00.1 0000:01:00.2 0000:01:00.3; do
    if [ -e "/sys/bus/pci/devices/$dev" ]; then
        echo 1 > "/sys/bus/pci/devices/$dev/remove"
    fi
done

# 4. ФІНАЛЬНИЙ УДАР: Видаляємо саму відеокарту
# Якщо її немає в системі - її неможливо розбудити.
if [ -e "/sys/bus/pci/devices/$GPU" ]; then
    # Спершу ставимо auto, щоб вона підготувалась до сну
    echo auto > "/sys/bus/pci/devices/$GPU/power/control"
    # Чекаємо 2 секунди
    sleep 2
    # Видаляємо пристрій назавжди (до перезавантаження)
    echo 1 > "/sys/bus/pci/devices/$GPU/remove"
fi

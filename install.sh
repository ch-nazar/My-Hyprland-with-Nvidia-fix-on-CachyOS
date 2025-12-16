#!/bin/bash
# Скрипт автоматичного відновлення налаштувань

echo "Починаю відновлення конфігів..."

# 1. Копіюємо папки користувача
cp -r config/* ~/.config/
echo "Конфіги (Hyprland, Ax-Shell, Kitty, Fish) відновлено."

# 2. Відновлюємо скрипти NVIDIA
echo "Відновлюю системні скрипти..."
sudo cp system-scripts/gpu-off.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/gpu-off.sh

sudo cp system-scripts/gpu-kill.service /etc/systemd/system/
sudo systemctl enable gpu-kill.service

echo "Все готово! Перезавантажте комп'ютер."


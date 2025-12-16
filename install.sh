#!/bin/bash

# --- НАЛАШТУВАННЯ КОЛЬОРІВ ДЛЯ КРАСИ ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ПОЧАТОК ВІДНОВЛЕННЯ СИСТЕМИ (CACHYOS + HYPRLAND) ===${NC}"

# Перевірка, чи ми в правильній папці
if [ ! -f "pkglist.txt" ]; then
    echo -e "${RED}Помилка: Не знайдено pkglist.txt! Ви забули його створити?${NC}"
    exit 1
fi

# 1. ВСТАНОВЛЕННЯ ПРОГРАМ
echo -e "${GREEN}[1/4] Встановлення програм зі списку...${NC}"
# Використовуємо paru (стандарт для CachyOS) або yay
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
else
    echo -e "${RED}Не знайдено paru або yay. Встановіть їх вручну!${NC}"
    exit 1
fi

# Оновлюємо базу і ставимо все зі списку (пропускаємо, якщо вже стоїть)
$AUR_HELPER -Syu --needed - < pkglist.txt

# 2. КОПІЮВАННЯ КОНФІГІВ
echo -e "${GREEN}[2/4] Відновлення налаштувань (Dotfiles)...${NC}"

# Створюємо бекап старих конфігів на всяк випадок
mkdir -p ~/.config-backup
cp -r ~/.config/hypr ~/.config-backup/ 2>/dev/null
cp -r ~/.config/fish ~/.config-backup/ 2>/dev/null
cp -r ~/.config/kitty ~/.config-backup/ 2>/dev/null
cp -r ~/.config/Ax-Shell ~/.config-backup/ 2>/dev/null

# Копіюємо нові
cp -r config/* ~/.config/
echo "Конфіги скопійовано у ~/.config/"

# 3. НАЛАШТУВАННЯ NVIDIA (ВАШ ФІКС)
echo -e "${GREEN}[3/4] Встановлення скриптів для NVIDIA...${NC}"

# Копіюємо скрипт-вбивцю
sudo cp system-scripts/gpu-off.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/gpu-off.sh

# Копіюємо і вмикаємо сервіс
sudo cp system-scripts/gpu-kill.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable gpu-kill.service

# Вимикаємо конфліктні сервіси (якщо вони встановились)
sudo systemctl disable --now supergfxd 2>/dev/null

# Якщо був конфіг процесора
if [ -f "system-scripts/auto-cpufreq.conf" ]; then
    sudo cp system-scripts/auto-cpufreq.conf /etc/
fi

# 4. ФІНАЛЬНІ ШТРИХИ
echo -e "${GREEN}[4/4] Налаштування оболонки...${NC}"

# Робимо Fish дефолтним, якщо це ще не так
if [[ $SHELL != "/usr/bin/fish" ]]; then
    chsh -s /usr/bin/fish
fi

echo -e "${BLUE}=== ГОТОВО! ===${NC}"
echo -e "${GREEN}Система відновлена. Перезавантажте комп'ютер, щоб скрипт NVIDIA спрацював.${NC}"

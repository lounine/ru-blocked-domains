#### Скачать и обновить все списки доменов до последней версии:
```bash
curl -fsSL 'https://github.com/lounine/ru-blocked-domains/releases/latest/download/update-geosites.sh' \
  | sudo bash
```

Скрипт ищет списки доменов в стандартных местах установки xray/v2ray: `/usr/share/...` и `/usr/local/share/...`. 
Нестандартную папку со списком доменов можно передать в качестве параметра:
```bash
curl -fsSL 'https://github.com/lounine/ru-blocked-domains/releases/latest/download/update-geosites.sh' \
  | sudo bash -s -- -g /some/other/location/
```

#### Настроить автоматическое ежедневное обновление списков доменов:
```bash
sudo curl -fsSL 'https://github.com/lounine/ru-blocked-domains/releases/latest/download/update-geosites.sh' \
  | sudo install /dev/stdin /etc/cron.daily/update-geosites
```

И при необходимости обновить немедленно:
```
sudo /etc/cron.daily/update-geosites
```

## Списки заблокированных в РФ доменов в формате xray / v2ray
Родные власти в постоянной заботе о несознательных россиянах блокируют множество сайтов, на которые нам совершенно незачем ходить. Долг каждого сознательного гражданина – помочь Родине в этом нелёгком деле. Этот репозиторий – попытка собрать список всех запрещённых доменов, на которые в минуты слабости может захотеться зайти. Используйте его, чтобы ещё надёжнее заблокировать всё запретное.

### Источники и структура данных
В список попадают:
- в раздел `antifilter-community` – все домены из списка **Community** проекта [Antifilter](https://antifilter.download)
- в раздел `itdoginfo-inside` – все домены из списка **src/Russia-domains-inside.lst** репозитория [@itdoginfo/allow-domains](https://github.com/itdoginfo/allow-domains)
- в раздел `itdoginfo-outside` – все домены из списка **src/Russia-domains-outside.lst** репозитория [@itdoginfo/allow-domains](https://github.com/itdoginfo/allow-domains)
- в раздел `all` – все недоступные из РФ домены из всех списков выше
- в раздел `all-outside` – все недоступные из-за пределов РФ российские домены из всех списков выше

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

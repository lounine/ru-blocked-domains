# Списки заблокированных в РФ доменов в формате v2ray / xray
Родные власти в постоянной заботе о несознательных россиянах блокируют множество сайтов, на которые нам совершенно незачем ходить. Долг каждого сознательного гражданина – помочь Родине в этом нелёгком деле. Этот репозиторий – попытка собрать список всех запрещённых доменов, на которые в минуты слабости может захотеться зайти. Используйте его, чтобы ещё надёжнее заблокировать всё запретное.

## Общий принцип работы
Сервер v2ray/xray – своего рода прокси, который может перенаправлять часть трафика на другой, удалённый v2ray/xray сервер по защищённому и сложно детектируемому протоколу. Используя списки запрещённых доменов можно перенаправить запросы на них на заграничный VPS (а там блокировать, разумеется).
Подробнее см. [v2ray](https://www.v2ray.com/ru/), [xray](https://xtls.github.io/en/).

## Источники и структура данных
В файл **ru-blocked.dat** попадают:
- в раздел `antifilter-community` – все домены из списка **Community** проекта [Antifilter](https://antifilter.download)
- в раздел `itdoginfo-inside` – все домены из списка **src/Russia-domains-inside.lst** репозитория [@itdoginfo/allow-domains](https://github.com/itdoginfo/allow-domains)
- в раздел `itdoginfo-outside` – все домены из списка **src/Russia-domains-outside.lst** репозитория [@itdoginfo/allow-domains](https://github.com/itdoginfo/allow-domains)
- в раздел `all` – все недоступные из РФ домены из всех списков выше
- в раздел `all-outside` – все недоступные из-за пределов РФ российские домены из всех списков выше

Релиз собирается ежедневно в 21:00 UTC (00:00 MSK), если в указанных выше списках были изменения.

## Установка

### Вручную
Скачать файл **ru-blocked.dat** из последнего релиза и поместить его в папку `/usr/share/xray`, `/usr/share/v2ray`, `/usr/local/share/xray` или `/usr/local/share/v2ray`, в зависимости от места установки v2ray/xray.

### Автоматически
В релиз включён скрипт **update-geosites.sh**. Скрипт скачает и обновит файл **ru-blocked.dat** из этого репозитория, а также **geoip.dat** и **geosite.dat** из дистрибутива v2ray/xray до последних версий. 

Скачать и запустить скрипт:
```bash
curl -fsSL 'https://github.com/lounine/ru-blocked-domains/releases/latest/download/update-geosites.sh' \
  | sudo bash
```

Скрипт автоматически установит списки доменов в стандартную папку v2ray/xray в `/usr/share/...` или `/usr/local/share/...`. 
Нестандартную место установки можно передать в качестве параметра:
```bash
curl -fsSL 'https://github.com/lounine/ru-blocked-domains/releases/latest/download/update-geosites.sh' \
  | sudo bash -s -- -g /some/other/location/
```

### Настройка периодического обновления доменов
Для ежедневного обновления списков предлагается запускать тот же скрипт через cron. Релиз собирается к 21:00 UTC (00:00 MSK), а cron.daily запускается на большинстве систем около 6:00 - 7:00, и  как раз подхватит последнюю версию.

Скачать скрипт и установить его в cron для ежедневного запуска:
```bash
curl -fsSL 'https://github.com/lounine/ru-blocked-domains/releases/latest/download/update-geosites.sh' \
  | sudo install /dev/stdin /etc/cron.daily/update-geosites
```

## Использование

### Конфигурация v2ray / xray
Пример обращения к спискам доменов в настройке маршрутизации:
```
"routing": {
  "rules": [
    {
      "type": "field",
      "domain": [ "ext:ru-blocked.dat:all" ],
      "outboundTag": "some-tag"
    },
    {
      "type": "field",
      "domain": [ "ext:ru-blocked.dat:all-outside" ],
      "outboundTag": "some-other-tag"
    }
  ]
}
```

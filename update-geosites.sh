#! /bin/bash

while test $# -gt 0
do case "$1" in
    -s|--service-name )       shift; service_name=$1 ;;
    -g|--geosite-location )   shift; geosite_location=$(realpath "$1") ;;
    * )                       echo "Error: bad option $1"; exit ;;
esac; shift; done


if [ -z "$service_name" ]; then
  for name in 'xray' 'v2ray'; do
    if [ -f /etc/systemd/system/$name.service ]; then
      service_name=$name
      echo "Guessed service name: $service_name"
      break
    fi
  done
fi
[ -z "$service_name" ] && { echo "Error: no xray/v2ray service found or provided"; exit 1; }

if [ -z "$geosite_location" ]; then
  for location in "/usr/share/$service_name" "/usr/local/share/$service_name"; do
    if [ -d "$location" ]; then
      geosite_location=$location
      echo "Guessed geosite location: $geosite_location"
      break
    fi
  done
fi
[ -z "$geosite_location" ] && { echo "Error: no xray/v2ray geosite location found or provided"; exit 1; }
[ -d "$geosite_location" ] || { echo "Invalid geosite location: $geosite_location"; exit 1; }

release_url='https://github.com/lounine/ru-blocked-domains/releases/latest/download/'

sha256sum=$(curl --location --fail --no-progress-meter "$release_url/ru-blocked.dat.sha256sum")

cd "$geosite_location"
if echo "$sha256sum" | sha256sum --check >/dev/null 2>&1; then
  echo "Geosite file is up to date"; exit 0
fi

temp_dir=$(mktemp -d)
[ -d "$temp_dir" ] || { echo "Error: failed to create temp directory"; exit 1; }
function cleanup { rm -rf "$temp_dir"; }; trap cleanup EXIT

echo "Downloading new geosite file"
cd "$temp_dir"
if ! curl --location --fail --no-progress-meter --remote-name "$release_url/ru-blocked.dat"; then
  echo "Error: failed to download geosite file"; exit 1
fi

if ! echo "$sha256sum" | sha256sum --check --quiet; then
  echo "Error: downloaded file checksum mismatch"; exit 1
fi

if systemctl is-active $service_name; then
  echo "Stopping $service_name service"
  systemctl stop $service_name
  do_restart=true
fi

echo "Updating geosite file"
cp "ru-blocked.dat" "$geosite_location/ru-blocked.dat"

if do_restart; then
  echo "Restarting $service_name service"
  systemctl start $service_name
fi

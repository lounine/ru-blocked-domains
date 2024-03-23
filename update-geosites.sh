#! /bin/bash

errcho() { >&2 echo "Error: $@"; }
errxit() { errcho "$@"; exit 1; }

while test $# -gt 0
do case "$1" in
    -s|--service-name )       shift; service_name=$1 ;;
    -g|--geosite-location )   shift; geosite_location=$(realpath "$1") ;;
    * )                       errxit "Bad option $1" ;;
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
[ -z "$service_name" ] && errxit "No xray/v2ray service found or provided"

if [ -z "$geosite_location" ]; then
  for location in "/usr/share/$service_name" "/usr/local/share/$service_name"; do
    if [ -d "$location" ]; then
      geosite_location=$location
      echo "Guessed geosite location: $geosite_location"
      break
    fi
  done
fi
[ -z "$geosite_location" ] && errxit "No xray/v2ray geosite location found or provided"
[ -d "$geosite_location" ] || errxit "Invalid geosite location '$geosite_location'"

temp_dir=''
function cleanup_temp_dir { 
  [ -z "$temp_dir" ] && return
  rm -rf "$temp_dir"
  temp_dir=''
}
function create_temp_dir {
  [ -n "$temp_dir" ] && return
  temp_dir=$(mktemp -d)
  [ -d "$temp_dir" ] || errxit "Failed to create temp directory"
}

function restart_service() {
  if [ "$service_restart_needed" = true ]; then
    echo "Restarting $service_name service"
    systemctl start $service_name
    service_restart_needed=false
  fi
}

function clean_up { cleanup_temp_dir; restart_service; }
trap clean_up EXIT

release_url='https://github.com/lounine/ru-blocked-domains/releases/latest/download/'

sha256sum=$(curl --location --fail --no-progress-meter "$release_url/ru-blocked.dat.sha256sum")

cd "$geosite_location"
if echo "$sha256sum" | sha256sum --check >/dev/null 2>&1; then
  echo "Geosite file is up to date"; exit 0
fi

echo "Downloading new geosite file"
create_temp_dir; cd "$temp_dir"
if ! curl --location --fail --no-progress-meter --remote-name "$release_url/ru-blocked.dat"; then
  errxit "Failed to download geosite file"
fi

if ! echo "$sha256sum" | sha256sum --check --quiet; then
  errxit "Downloaded file checksum mismatch"
fi

if systemctl is-active $service_name; then
  echo "Stopping $service_name service"
  systemctl stop $service_name
  service_restart_needed=true
fi

echo "Updating geosite file"
cp "ru-blocked.dat" "$geosite_location/ru-blocked.dat"

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

function create_temp_dir {
  [ -d "$temp_dir" ] && return
  temp_dir=$(mktemp -d)
  [ -d "$temp_dir" ] || errxit "Failed to create temp directory"
}

function cleanup_temp_dir { 
  rm -rf "$temp_dir"
  temp_dir=''
}

service_restart_needed=false

function stop_service() {
  systemctl is-active $service_name || return
  echo "Stopping $service_name service"
  systemctl stop $service_name
  service_restart_needed=true
}

function restart_service() {
  $service_restart_needed || return
  echo "Restarting $service_name service"
  systemctl start $service_name
  service_restart_needed=false
}

function clean_up { cleanup_temp_dir; restart_service; }
trap clean_up EXIT

function download_if_changed() {
  file_url="https://github.com/$1/releases/latest/download/$2"

  sha256sum=$(curl --location --fail --no-progress-meter "${file_url}.sha256sum")

  cd "$geosite_location"
  if echo "$sha256sum" | sha256sum --check >/dev/null 2>&1; then
    echo "Geosite file '$2' is up to date"; return
  fi

  create_temp_dir; cd "$temp_dir"

  echo "Downloading file '$2' from '$1' latest release"
  if ! curl --location --fail --no-progress-meter --remote-name "$file_url"; then
    errxit "Failed to download '$file_url'"
  fi

  if ! echo "$sha256sum" | sha256sum --check --quiet; then
    errxit "Downloaded file '$2' checksum mismatch"
  fi
}

download_if_changed 'v2fly/geoip' 'geoip.dat'
download_if_changed 'v2fly/domain-list-community' 'dlc.dat'
download_if_changed 'lounine/ru-blocked-domains' 'ru-blocked.dat'

if compgen -G "$temp_dir/*.dat" > /dev/null; then
  stop_service
  for downloaded_file in "$temp_dir"/*.dat; do
    file=$(basename "$downloaded_file")
    echo "Updating geosite file '$file'"
    cp "$downloaded_file" "$geosite_location/$file"
  done
fi

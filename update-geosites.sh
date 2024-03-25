#! /bin/bash

function errcho { >&2 echo "Error: $@"; }
function errxit { errcho "$@"; exit 1; }

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
[ -z "$geosite_location" ] && errxit "No $service_name geosite location found or provided"
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

function stop_service {
  systemctl is-active --quiet $service_name || return
  echo "Stopping $service_name service"
  systemctl stop $service_name
  service_restart_needed=true
}

function restart_service {
  $service_restart_needed || return
  echo "Restarting $service_name service"
  systemctl start $service_name
  service_restart_needed=false
}

function download {
  curl --location --fail --silent --show-error --retry 3 --max-time 15 "$@" || errxit "Failed to download '${@: -1}'"
}

function clean_up { cleanup_temp_dir; restart_service; }
trap clean_up EXIT

function download_if_changed {
  repo=$1
  file=$2
  name=${3:-$2}

  file_url="https://github.com/$repo/releases/latest/download/$file"

  echo "Downloading '$name' checksum from '$repo' latest release"
  sha256sum=$(download "${file_url}.sha256sum") || exit 1
  sha256sum=${sha256sum/$file/$name}

  cd "$geosite_location"
  if echo "$sha256sum" | sha256sum --check >/dev/null 2>&1; then
    echo "File '$name' is already up to date"
    return
  fi

  create_temp_dir; cd "$temp_dir"

  echo "Downloading '$name' from '$repo' latest release"
  download --output "$name" "$file_url"

  echo "$sha256sum" | sha256sum --check --quiet || errxit "Downloaded file '$name' checksum mismatch"
}

download_if_changed 'v2fly/geoip' 'geoip.dat'
download_if_changed 'v2fly/domain-list-community' 'dlc.dat' 'geosite.dat'
download_if_changed 'lounine/ru-blocked-domains' 'ru-blocked.dat'

if compgen -G "$temp_dir/*.dat" > /dev/null; then
  stop_service
  for downloaded_file in "$temp_dir"/*.dat; do
    file=$(basename "$downloaded_file")
    echo "Updating file '$file'"
    [ -f "$geosite_location/$file" ] && cp "$geosite_location/$file" "$geosite_location/$file.bak"
    cp "$downloaded_file" "$geosite_location/$file"
  done
fi

#! /bin/bash

function clean-up() { grep -v -e '^#' -e '^[[:space:]]*$' | sed 's/^www\.//' | sort | uniq; }

cat "$1"/antifilter-community.lst  | clean-up > "$2"/antifilter-community
cat "$1"/itdoginfo-inside.lst      | clean-up > "$2"/itdoginfo-inside
cat "$1"/itdoginfo-outside.lst     | clean-up > "$2"/itdoginfo-outside
cat "$1"/itdoginfo-outside.lst     | clean-up > "$2"/all-outside
( \
cat "$1"/antifilter-community.lst; \
cat "$1"/itdoginfo-inside.lst \
                                ) | clean-up > "$2"/all

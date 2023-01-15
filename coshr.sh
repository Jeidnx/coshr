#!/usr/bin/env bash

set -e

VERSION="0.2"

usage () {
  >&2 echo 'coshr - easily share your command output'
  >&2 echo "Usage: coshr [options] '<cmd>'"
  >&2 echo '  -h            Show this help page'
  >&2 echo '  -V            Print version number and quit'
  >&2 echo '  -v            Show verbose output'
  >&2 echo '  -f <format>   Change output format'
  >&2 echo '  -l <language> Add <language> to code block. Only works with markdown format'
  >&2 echo '  -u            Upload output to 0x0'
  >&2 echo '  -o            Copy output without prepending <cmd>'
}

# shellcheck source=/dev/null
FILE="$HOME/.config/coshr/config" && test -f "$FILE" && source "$FILE"

FORMAT="${FORMAT:-md}"
INSTANCE="${INSTANCE:-0x0.st}"
TEMPLATE="${TEMPLATE:-/usr/share/doc/coshr/template.html}"
VERBOSE=
UPLOAD=

while getopts ':hVvf:l:uo' arg; do
  case "${arg}" in
    h)
      usage
      exit 0;;
    v)VERBOSE=true;;
    V)
      echo "coshr version: $VERSION"
      exit 0;;
    f)FORMAT="$OPTARG";;
    l)ANNOTATION="$OPTARG";;
    u)UPLOAD=true;;
    o)HIDECMD=true;;
    :)
      echo "$0: Must supply an argument to '-$OPTARG'." >&2
      exit 1;;
    ?)
      echo "$0: Invalid option '-${OPTARG}'" >&2
      exit 2;;
  esac
done
shift $((OPTIND-1))

out=""
cmd=""

if test ! -t 0; then
  [ -n "$VERBOSE" ] && echo "[VERBOSE] reading from stdin"
  HIDECMD=true
  cmd=$(cat)
else
  [ -n "$VERBOSE" ] && echo "[VERBOSE] executing command: '$*'"
  if [ -z "${*+x}" ]; then
    echo "Error: No command supplied."
    exit 1
  fi
  cmd=$(bash -c "$@")
fi

cmd=$(echo "$cmd" | \
  # https://stackoverflow.com/a/51141872 
    sed 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g')

if [ "$VERBOSE" ]; then
  if [ "$HIDECMD" ]; then
    echo "[VERBOSE] not showing command in markdown"
  else
    echo "[VERBOSE] showing command in markdown"
  fi
  [ -n "$ANNOTATION" ] && echo "[VERBOSE] annotating markdown with: '$ANNOTATION'"
  [ "$UPLOAD" ] && echo "[VERBOSE] using 0x0 instance: '$INSTANCE'"
fi

case "$FORMAT" in
  md)
    # shellcheck disable=SC2124
    [ "$HIDECMD" ] || out+='`'"$@"'`\n'
    out+='````'"${ANNOTATION}"'\n'"${cmd}"'\n````';;
  plain)
    # shellcheck disable=SC2124
    [ "$HIDECMD" ] || out+="$@\n\n"
    out+="${cmd}";;
  html)
    [ "$VERBOSE" ] && echo "[VERBOSE] using HTML template: '$TEMPLATE'"
    if [ "$HIDECMD" ]; then
      out+=$(sed -e '/<!--STARTCMD--!>/,/<!--ENDCMD--!>/d' -e '/<!--OUTPUT--!>/{r /dev/stdin' -e ';d;}' "$TEMPLATE" <<<"$cmd")
    else
      out+=$(sed -e "s#<!--CMD--!>#$*#g" -e '/<!--OUTPUT--!>/{r /dev/stdin' -e ';d;}' "$TEMPLATE" <<<"$cmd")
    fi;;
  *)
    >&2 echo "Unrecognized format '$FORMAT'. Available options: 'md','plain', 'html'"
    exit 1;;
esac

echo -e "$cmd"

if [ "$UPLOAD" ]; then
  >&2 echo -n "Continue with upload [y|n] (n): "
  read -r answer
  if [ "$answer" == "y" ]; then
    response=$(echo -e "$out" | curl -i -F'file=@-' -Fsecret= "$INSTANCE")
    expires=$(echo "$response" | grep -i "x-expires" | cut -d' ' -f2)
    token=$(echo "$response" | grep -i "x-token" | cut -d' ' -f2)
    >&2 echo "Token: $token"
    >&2 echo "Expires: $(date -d @"$expires")"
    echo "$response" | tail --lines 1 | wl-copy
  else
    >&2 echo "Aborting."
    exit 1
  fi
  exit 0
fi

echo -e "$out" | wl-copy

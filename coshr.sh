#!/usr/bin/env bash

set -e

VERSION="0.3"

usage () {
  >&2 echo 'coshr - easily share your command output'
  >&2 echo "Usage: coshr [options] '<cmd>'"
  >&2 echo '  -h            Show this help page'
  >&2 echo '  -V            Print version number and quit'
  >&2 echo '  -v            Show verbose output'
  >&2 echo '  -e            Capture also stderr (no effect when reading from stdin)'
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

while getopts ':hVvef:l:uo' arg; do
  case "${arg}" in
    h)
      usage
      exit 0;;
    v)VERBOSE=true;;
    e)CAPTURE_ERROR=true;;
    V)
      echo "coshr version: $VERSION"
      exit 0;;
    f)FORMAT="$OPTARG";;
    l)ANNOTATION="$OPTARG";;
    u)UPLOAD=true;;
    o)HIDECMD=true;;
    :)
      echo "Error: Must supply an argument to '-$OPTARG'." >&2
      exit 1;;
    ?)
      echo "Error: Invalid option '-${OPTARG}'" >&2
      exit 2;;
  esac
done
shift $((OPTIND-1))

out=""
cmd=""

if test ! -t 0; then
  [ -n "$VERBOSE" ] && echo "[VERBOSE] reading from stdin"
  HIDECMD=true
  while IFS= read -r line; do
    echo "$line"
    cmd+="$line\n"
  done < <(sed -u 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g')
else
  if [ -z "${*+x}" ]; then
    echo "Error: No command supplied."
    exit 1
  fi
  [ -n "$VERBOSE" ] && echo "[VERBOSE] executing command: '$*'"
  if [ -n "$CAPTURE_ERROR" ]; then
     while IFS= read -r line; do
      echo "$line"
      cmd+="$line\n"
    done < <(2>&1 bash -c "$@" | sed -u 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g')
  else
     while IFS= read -r line; do
      echo "$line"
      cmd+="$line\n"
    done < <(bash -c "$@" 2>/dev/null | sed -u 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g')
  fi
fi

if [ -n "$VERBOSE" ]; then
  if [ -n "$HIDECMD" ]; then
    echo "[VERBOSE] not showing command in markdown"
  else
    echo "[VERBOSE] showing command in markdown"
  fi
  [ -n "$ANNOTATION" ] && echo "[VERBOSE] annotating markdown with: '$ANNOTATION'"
  [ -n "$UPLOAD" ] && echo "[VERBOSE] using 0x0 instance: '$INSTANCE'"
fi

case "$FORMAT" in
  md)
    # shellcheck disable=SC2124
    [ -n "$HIDECMD" ] || out+='`$ '"$@"'`\n'
    out+='````'"${ANNOTATION}"'\n'"${cmd}"'````';;
  plain)
    # shellcheck disable=SC2124
    [ -n "$HIDECMD" ] || out+='$ '"$@\n\n"
    out+="${cmd}";;
  html)
    [ -n "$VERBOSE" ] && echo "[VERBOSE] using HTML template: '$TEMPLATE'"
    if [ -n "$HIDECMD" ]; then
      out+=$(sed -e '/<!--STARTCMD--!>/,/<!--ENDCMD--!>/d' -e '/<!--OUTPUT--!>/{r /dev/stdin' -e ';d;}' "$TEMPLATE" <<<"$cmd")
    else
      out+=$(sed -e "s#<!--CMD--!>#$*#g" -e '/<!--OUTPUT--!>/{r /dev/stdin' -e ';d;}' "$TEMPLATE" <<<"$cmd")
    fi;;
  *)
    >&2 echo "Unrecognized format '$FORMAT'. Available options: md, plain, html"
    exit 1;;
esac

if [ -n "$UPLOAD" ]; then
  >&2 echo -n "Continue with upload [y|n] (n): "
  read -r answer </dev/tty
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

echo -en "$out" | wl-copy

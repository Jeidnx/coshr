#!/usr/bin/env bash

VERSION="0.1"

usage () {
  echo 'coshr - easily share your command output'
  echo "Usage: coshr [options] '<cmd>'"
  echo -e '  -h            Show this help page'
  echo -e '  -V            Print version number and quit'
  echo -e '  -v            Show verbose output'
  echo -e '  -l <language> Add <language> to code block'
  echo -e '  -o            Copy output wihtout prepending <cmd>'
}

while getopts 'hvVl:o' arg; do
  case "${arg}" in
    h)
      usage
      exit 0;;
    v)VERBOSE=true;;
    V)
      echo "coshr version: $VERSION"
      exit 0;;
    l)ANNOTATION="$OPTARG";;
    o)HIDECMD=true;;
  esac
done
shift $((OPTIND-1))

if [ -z "${@+x}" ]; then
  echo "Error: No command supplied."
  exit 1
fi

if [ "$VERBOSE" ]; then
  echo "[VERBOSE] executing command: '$@'"
  if [ -z "${HIDECMD+x}" ]; then
    echo "[VERBOSE] showing command in markdown"
  else
    echo "[VERBOSE] not showing command in markdown"
  fi
  [ -n "$ANNOTATION" ] && echo "[VERBOSE] annotating markdown with: '$ANNOTATION'"
fi

cmd=$(bash -c "$@" | \
  # https://stackoverflow.com/a/51141872 
  sed 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g')

echo "$cmd"

out=""

[ -z "${HIDECMD+x}" ] && out+=$(echo '`'"$@"'`\n')
out+=$(echo '````'"${ANNOTATION}"'\n'"${cmd}"'\n````')
echo -e "$out" | wl-copy

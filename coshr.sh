#!/usr/bin/env bash

VERSION="0.1"

usage () {
  >&2 echo 'coshr - easily share your command output'
  >&2 echo "Usage: coshr [options] '<cmd>'"
  >&2 echo '  -h            Show this help page'
  >&2 echo '  -V            Print version number and quit'
  >&2 echo '  -v            Show verbose output'
  >&2 echo '  -l <language> Add <language> to code block'
  >&2 echo '  -o            Copy output without prepending <cmd>'
}

while getopts ':hvVl:o' arg; do
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

  [ -z "${HIDECMD+x}" ] && out+='`'"$@"'`\n'
fi

cmd=$(echo "$cmd" | \
  # https://stackoverflow.com/a/51141872 
    sed 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g')

if [ "$VERBOSE" ]; then
  if [ -z "${HIDECMD+x}" ]; then
    echo "[VERBOSE] showing command in markdown"
  else
    echo "[VERBOSE] not showing command in markdown"
  fi
  [ -n "$ANNOTATION" ] && echo "[VERBOSE] annotating markdown with: '$ANNOTATION'"
fi

echo -e "$cmd"

out+='````'"${ANNOTATION}"'\n'"${cmd}"'\n````'
echo -e "$out" | wl-copy

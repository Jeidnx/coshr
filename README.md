# coshr

Command Output Share

`coshr` is a bash script which allows you to easily share output of your
commands with someone else. It shows you the content of the command that
was run, formats it into markdown and copies it to your clipboard.

currently only works on wayland with wl-clipboard

### Installing

if you are on arch linux you can use the
[coshr-git](https://aur.archlinux.org/packages/coshr-git) AUR package.

Everyone else has to add this script to their $PATH manually.

if you want to quickly copy your last action, you can paste this snippet
into your shells rc file. Usage is the same as coshr, but instead of
providing a command, it uses your last ran command automatically.
```sh
coshrl() {
  coshr "$@" "$(fc -ln -1)"
}
```

### TODO:
 - Fix error where markdown is malformatted when 4 backticks are in the
output of the command
 - Enable the use of clipboards other than wl-clipboard
 - Print output to stdout as it comes in
 - Enable piping input into coshr (this will automaticly use -o)
 - Enable formatting of copied text for already ran commands which can't
 be re-run quickly
 - Enable more output formats (html, plain, pastebin)
 - Add config file for
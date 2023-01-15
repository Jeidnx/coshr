# coshr

Command Output Share

`coshr` is a bash script which allows you to easily share output of your
commands with someone else. It previews the output of the command that
was run, formats it to your liking and either copies it to your clipboard
or uploads it directly to 0x0.

currently only works on wayland with wl-clipboard

### Usage

The usage is best explained with some examples. If you want to follow
along using the `-v` option helps you figure out what coshr is doing.

#### Basics

`````
$ coshr 'echo Hello World!'
Hello World!
$ wl-paste
`echo Hello World!`
````
Hello World!
````
`````


If you don't want to include the command you ran in your output add the `-o` flag:
`````
$ coshr -o 'echo Hello World!'
Hello World!
$ wl-paste
````
Hello World!
````
`````

You can also use stdin, note that this assumes `-o` because in this case
coshr can't read which command you entered.

``````
$ echo "Hello World!" | coshr
Hello World!
$ wl-paste
````
Hello World!
````
``````

As you can see reading from stdin produces the same results as using
the `-o` option.

#### Formats

As you probably noticed the default output format is markdown. You can
specify which format you want to use with the `-f <format>` flag.
Currently, there are 3 available formats:

 - `md` for markdown
 - `plain` for no formatting at all
 - `html` for generating html based on a template

```
$ coshr -f plain 'echo "Hello World!"'
Hello World!
$ wl-paste
echo "Hello World!"

Hello World!
```

#### Uploading

If you want to upload the command output instead of copying it to your
clipboard you can use the `-u` option. This will upload what would
normally be copied to your clipboard to 0x0 and copy the URL into your
clipboard. This works great in combination with `-f html`.

```
$ coshr -f html -u 'fortune | cowsay'
______________________________________ 
/ Live from New York ... It's Saturday \
\ Night!                               /
 -------------------------------------- 
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
Continue with upload [y|n] (n): y
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1356  100    49  100  1307    663  17706 --:--:-- --:--:-- --:--:-- 18575
Token: <censored>
Expires: Wed Apr 14 12:11:00 AM CEST 56010
$ wl-paste
https://0x0.st/s/YscbVnUp_YQGahc9JNTGlQ/o7Ri.html
```

#### HTML

coshr can generate HTML for your output using `-f html`. This HTML is
based on a template (by default '/usr/share/doc/coshr/template.html').
The template file includes 4 HTML comments which let coshr know what it
should do with the template.

 - `<!--STARTCMD--!>` designates the start of the CMD section.
 - `<!--CMD--!>` is going to be replaced by the name of the command.
 - `<!--ENDCMD--!>` designates the end of the CMD section.
 - `<!--OUTPUT--!>` is going to be replaced by the output of the command.

As we covered earlier coshr doesn't always know and / or use the command
you ran in its output. If this is the case, everything in the CMD
section is removed from the output html.

A good starting point can be found in the example [template](./template.html)

#### Special characters

coshr automatically removes special characters from the output of your
command in order to properly display it. Coshr will preview the output
after it has been filtered. A great example of this is `neofetch`, where
you can see that the colors are stripped and the formatting is a little
different. Try it for yourself.

```
$ neofetch | coshr
```

#### Configuration

you can place a configuration file in `$HOME/.config/coshr/config`. This
file is getting sourced at the beginning of the script, so it's a simple
KEY=VALUE file. The command line arguments always overwrite the config.
Following keys are allowed:

 - `FORMAT` specifies the default format.
 - `INSTANCE` URL for the 0x0 instance you want to use.
 - `TEMPLATE` Path to the HTML template you want to use.

### Installing

if you are on arch linux you can use the
[coshr-git](https://aur.archlinux.org/packages/coshr-git) AUR package.

For everyone else you can:

 1. Clone the repo:
    ```
    git clone https://github.com/jeidnx/coshr
    ```
 2. Enter the repo:
    ```
    cd coshr
    ```
 3. Install via makefile
    ```
    sudo make install
    ```

if you want to quickly copy your last action, you can paste this snippet
into your shells rc file. Usage is the same as coshr, but instead of
providing a command, it uses your last ran command automatically.
```sh
coshrl() {
  coshr "$@" "$(fc -ln -1)"
}
```

### TODO:
 - Fix error where markdown is malformed when 4 backticks are in the
output of the command
 - Enable the use of clipboards other than wl-clipboard
 - Print output to stdout as it comes in
 - Enable formatting of copied text for already ran commands which can't
 be re-run quickly
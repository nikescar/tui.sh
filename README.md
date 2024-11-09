<h1>tui.sh</h1>

minimum Text User Interface in bash without ncurses. <br/>
just edit yaml and deploy or use in everyday workflow.

<h5>Table of Contents</h5>

- [features](#features)
- [on terminal, just two files](#on-terminal-just-two-files)
- [+ tui on web](#-tui-on-web)
- [usage](#usage)
- [tui.sh.yaml](#tuishyaml)
- [for developers](#for-developers)
  - [runtime hash check](#runtime-hash-check)
  - [forbid to use git clone, wget, curl commands in yaml file](#forbid-to-use-git-clone-wget-curl-commands-in-yaml-file)
  - [debug system](#debug-system)
  - [process histories](#process-histories)
  - [pagenations](#pagenations)
  - [httpd switch](#httpd-switch)
  - [communication with darkhttpd](#communication-with-darkhttpd)
  - [links](#links)
  - [todo](#todo)

## features

- require bash 4.1+ (available in [most(repology)](https://repology.org/project/bash/badges) os distribution.)
- simple navigation with keyboard input. no more.
- simultanious on-off transition to onscreen app like vim.
- same workflow, actions are available on tui_web, webapp.
- vim working on tui.sh
- htop, glancex, tmux, nano can't be run on tui.sh

## on terminal, just two files

- **tui.sh** - main tui application file.
- **tui.sh.yaml** - example main tui menu tree manifest with [yaml v1.2(yaml)](https://yaml.org/spec/1.2.2/#escaped-characters). no support for multiline, flow, anchor, tag, block, doc stream in yaml v1.2.

## + tui on web

- tui.**web.tar.gz** - show tui to web. do predefined actions, check logs and process status.
- require [**darkhttpd**(github)](https://github.com/emikulic/darkhttpd.git) installed. or simply compile it. check availability on your os pkg [here(repology)](https://repology.org/project/darkhttpd/badges).
- static solidjs webapp will serve as what tui.sh provides.
- threre are no cgi server, so tui_web communicates on access.log by requesting dummy url with data which encoded insecurly. it could be dangerous on remote connection, better using it through ssh tunnel.

## usage

```bash

❯ ./tui.sh --help

   Usage: tui.sh [--yaml YAMLFILE] [--root ROOTPATH] [--dbgfile DEBUGFILE] [--rtime TIMESECOND]
                    [--debug] [--dry-run]

   optional arguments:
     -h, --help                 show this help message and exit
     -y, --yaml YAMLFILE        yaml menu file(default./tui.sh.yaml)
     -r, --root ROOTPATH        absolute path of starting point on tree(default. /bkit)
     -b, --dbgfile DEBUGFILE    debug file path(default. ./tui.debug.log)
     -t, --rtime TIMESECOND     screen refresh time in float second(default. 1.1)
     -d, --debug                debug of the bash script
     --dry-run                  do a dry run, check only md file and exit

```

## tui.sh.yaml

menu and what to do in the menu in the tui.sh app.
realworld example for bkit [tui.sh.yaml(github)](./tui.sh.yaml)

```yaml
---
bkit: # root name
  _sha256sum: https://pastebin.com/raw/RscMWHhe # hash check for neccessary files.(tui.sh, tui.sh.yaml tui_web.tar.gz)
  _description: various setup scripts for security. # menu description.
  _batch: ["beginner", "advanced"] # set category for inclustion, exclustion at batch run.
  _keycode: b # keycode on enter the menu.
  _cmd:
    - echo "show output. no control" # command to run on screen without control.
    - sleep 100 & # run background as child processor. no control.
    - exec 1>**_tty_** && $EDITOR file # run on foregound over tui. control.
  _link:
    control: "/bkit/submenu" # direct menu link to other tree in control. . not implemented.
    link: "https://github.com/xxx/xxx" # web link. not implemented.
  status: # normal type submenu
    _description: status menu
    _keycode: t
    _cmd: echo "" # command entry to run on background.
  toggle: # on/off toggle type menu
    _keycode: g
    _description: toogle menu for on / off
    _cmd: echo ""
    _type: toggle # toggle type needs, _check_cmd and _disable_cmd attributes.
    _check_cmd: if [ -z ${tui_toggle+x} ]; then echo 1 && tui_toggle=1; else echo 0 && unset tui_toggle; fi # _check_cmd for enabled(print 1 or any string) or disabled(echo 0 or empty string)
    _disable_cmd: echo ""
```

## for developers

stuff to modify tui.sh.

### runtime hash check

download tui.sh hash<br/>
https://raw.githubusercontent.com/solidjs/solid/v1.8.0/LICENSE
https://cdn.jsdelivr.net/gh/solidjs/solid@v1.8.0/LICENSE
https://cdn.statically.io/gh/solidjs/solid/v1.8.0/LICENSE
https://cdn.staticdelivr.com/gh/solidjs/solid/v1.8.0/LICENSE
https://ghproxy.com/https://raw.githubusercontent.com/solidjs/solid/v1.8.0/LICENSE

### forbid to use git clone, wget, curl commands in yaml file

simple blocker for not to use script for binary download and runner.<br/>
tui.sh is scan input yaml file whether including git clone, wget, curl default.<br/>
please put your binary or setup script downloaded by end-user themselves if possible.

### debug system

tui.sh --loglv 3<br/>
\_tui_log 4 "test"

cat tui.debug.log

### process histories

[UP/DOWN] [C]lose<br/>
navigate through node on tree will generates process hitories like book page.<br/>
travel histories by arrow-up and arrow-down key. and close it by put [C] key.

### pagenations

[j/k]<br/>
in single node or process, travel logs by putting [j] key for page-up and page-down for [k] key.

### httpd switch

[t]web<br/>
httpd can be turned on with [t] key.

### communication with darkhttpd

- tui_web_responder started from tui.sh(-m tui_web). default configs in yaml tree on /root/\_tui_sh_config.
- open tui_web in browser and generate request to http://127.0.0.1:58080/dummy/tnet/1/2/YWRkcmVzczogL2JraXQvc3RhdHVzL2Z1bi90cmVlCmNvbnRlbnQ6IExvZ0ZldGNoZXIKc3VibWVudTogW10K__EOR__.
  - /dummy/tnet : prefix
  - /1 : request id
  - /2 : sequence on a single request.
  - /YWRk... : base64 encoded yaml data. split per 1000 chars for sing sequence.
  - \_\_EOR\_\_ : end of request
- request object makes request to http://127.0.0.1:58080/var/net/REQ00007 to check tui_web_respond received request.
- request object makes request to http://127.0.0.1:58080/var/net/RES00007 for gettting stdout of process.

### links

- [bash bible](https://github.com/dylanaraps/pure-bash-bible)
- [bash hackers wiki](https://flokoe.github.io/bash-hackers-wiki/howto/redirection_tutorial/?h=file+descriptor)
- [darkhttpd](https://github.com/emikulic/darkhttpd)
- [caddy](https://caddyserver.com/docs/quick-starts/caddyfile)
- [solidjs](https://start.solidjs.com/)

### todo

- example is work in progress. make it simpler.
- caddy is not working properly.
- webui components is not organized. tui components is not organized.

<h1>tui_web</h1>

web components for tui.sh.

<h5>Table of Contents</h5>

- [features](#features)
- [base](#base)
- [libs](#libs)
- [solidjs ui components](#solidjs-ui-components)
- [other readings](#other-readings)

# features

- service initiated from tui.sh with darkhttpd. optionally pure-ftpd.
- service from index.md(tui.tree.md) menu tree manuscript.
- manage/install/uninstall/configure/logs bkit packages.
- automatic sshd ssh client certificate generate https://github.com/bpkg/bpkg
- no cgi service required.
- tui_web client make action request to darkhttpd, tui.sh wathcing log for actions and the results back to static file in /proc folder.
- with tui_web you can edit config file and send it through pure-ftpd.

# base

- vanillajs components : https://vanillalist.top/
- solidjs : https://www.solidjs.com/docs/latest
- solidjs tutorials : https://www.solidjs.com/tutorial/introduction_basics
- solidjs-primitives : https://primitives.solidjs.community/package/lifecycle

# libs

- ansicolor :
- jsftp :

# solidjs ui components

- kobalte : solidjs simple components https://kobalte.dev/docs/core/overview/introduction
- apexcharts : https://apexcharts.com/javascript-chart-demos/?ref=vanillalist
- table : https://github.com/TanStack/table
- table-virtual : https://github.com/TanStack/virtual
- prismjs :
- handsontable? :

# other readings

- bash script bible : https://github.com/dylanaraps/pure-bash-bible
- user dir config git mgmt : https://github.com/RichiH/vcsh/blob/main/doc/README.md
- pid watcher with sysdig or strace : https://unix.stackexchange.com/questions/375387/how-to-trace-networking-activity-of-a-command

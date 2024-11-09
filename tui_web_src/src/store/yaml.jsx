import { createStore } from "solid-js/store";
import { createSignal, createEffect } from "solid-js";

const [selectedMenu, setSelectedMenu] = createSignal({
  address: [],
});
const [tuiTree, setTuiTree] = createStore({ tree: {} });
const [tuiConfig, setTuiConfig] = createStore({
  config: {
    tui_basic_auth: "test:test",
    tui_binding_ip: "127.0.0.1",
    tui_httpd_bin: "darkhttpd",
    tui_log_dir: "./.tui_web/var/log",
    tui_access_log: "access.log",
    tui_net_dir: "./.tui_web/var/net",
    tui_posting_address: "localhost",
    tui_run_dir: "./.tui_web/var/run",
    tui_web_dir: "./.tui_web",
    tui_web_port: 58080,
    transfer_field: "url",
  },
});

function parseConfig(yaml) {
  for (const [k1, v1] of Object.entries(yaml)) {
    for (const [k2, v2] of Object.entries(v1)) {
      if (k2 == "_tui_sh_config") {
        return v2;
      }
    }
  }
  return false;
}

function findSubmenuFromTop(yaml, menu) {
  var address = menu.split("/");
  address.shift();
  if (yaml == undefined) {
    return false;
  }
  var submenu = [];
  for (const [k, v] of Object.entries(yaml)) {
    if (address.length > 0 && k == address[0]) {
      address.shift();
      return findSubmenuFromTop(v, "/" + address.join("/"));
    } else {
      if (k[0] != "_" && k != "key") {
        submenu.push(k);
      }
    }
  }
  return submenu;
}

export {
  tuiTree,
  setTuiTree,
  selectedMenu,
  setSelectedMenu,
  tuiConfig,
  setTuiConfig,
  parseConfig,
  findSubmenuFromTop,
};

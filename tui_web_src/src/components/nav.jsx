import { A } from "@solidjs/router";
import { createStore, unwrap, reconcile } from "solid-js/store";
import {
  createSignal,
  createMemo,
  createEffect,
  onMount,
  For,
  Show,
  createResource,
  createReaction,
} from "solid-js";
import {
  tuiTree,
  setTuiTree,
  selectedMenu,
  setSelectedMenu,
} from "../store/yaml";
import { Menubar } from "@kobalte/core/menubar";
import { DropdownMenu } from "@kobalte/core/dropdown-menu";
import { Button } from "@kobalte/core/button";
import "./nav.css";
import { Popover } from "@kobalte/core/popover";
import { Dialog } from "@kobalte/core/dialog";
import { TextField } from "@kobalte/core/text-field";
import { ImCross } from "solid-icons/im";
import { BiSolidRightArrow } from "solid-icons/bi";

const [open, setOpen] = createSignal(false);
const onMenuSelected = (address, subtree) => {
  console.log(address);

  // console.log("selmenu", props, submenu);
  setSelectedMenu({ address: address });
};

const onSubmit = (props) => {
  // var sshhost = document.getElementById("sshhost").value;
  // if (sshhost.length > 0) {
  // }
  // var sshid = document.getElementById("sshid").value;
  // var sshpass = document.getElementById("sshpass").value;
  // console.log(sshhost, sshid, sshpass);
};

const MenuBar = (props) => {
  if (props?.node == undefined || props?.node == null) {
    return "";
  }
  var nodeval = [];
  for (const [key, value] of Object.entries(props.node)) {
    if (key[0] == "_" || key == "key" || value == null) continue;
    nodeval.push({
      key: key,
      ...value,
    });
  }
  // console.log(nodeval);
  var root = nodeval[0].key;
  return (
    <Menubar>
      <Menubar.Menu>
        <Menubar.Trigger
          class="menubar__trigger"
          onClick={(e) => onMenuSelected("/")}
        >
          Home
        </Menubar.Trigger>
      </Menubar.Menu>
      <Menubar.Menu>
        <Menubar.Trigger
          class="menubar__trigger"
          onClick={(e) => onMenuSelected("/" + root)}
        >
          Root
        </Menubar.Trigger>
      </Menubar.Menu>
      <For each={Object.entries(nodeval[0])}>
        {([k, v]) => (
          <Switch>
            <Match when={k[0] != "_" && typeof v === "object" && v != null}>
              <Menubar.Menu>
                <Menubar.Trigger class="menubar__trigger">{k}</Menubar.Trigger>
                <Menubar.Portal>
                  <Menubar.Content class="menubar__content">
                    <For each={Object.entries(v)}>
                      {([k2, v2]) => (
                        <Switch>
                          <Match
                            when={
                              k2[0] != "_" &&
                              typeof v2 === "object" &&
                              v2 != null &&
                              Object.keys(v2).filter(
                                (key) => key[0] != "_" && key != "key"
                              ).length != 0
                            }
                          >
                            <Menubar.Sub overlap gutter={4} shift={-8}>
                              <Menubar.SubTrigger
                                class="menubar__sub-trigger"
                                onClick={(e) =>
                                  onMenuSelected(
                                    "/" + [root, k, k2].join("/"),
                                    v2
                                  )
                                }
                              >
                                {k2}
                                <div class="dropdown-menu__item-right-slot">
                                  <BiSolidRightArrow />
                                </div>
                              </Menubar.SubTrigger>
                              <Menubar.Portal>
                                <Menubar.SubContent class="menubar__sub-content">
                                  <For each={Object.entries(v2)}>
                                    {([k3, v3]) => (
                                      <Switch>
                                        <Match
                                          when={
                                            k3[0] != "_" &&
                                            typeof v3 === "object" &&
                                            v3 != null &&
                                            Object.keys(v3).filter(
                                              (key) =>
                                                key[0] != "_" && key != "key"
                                            ).length != 0
                                          }
                                        >
                                          <Menubar.Sub
                                            overlap
                                            gutter={4}
                                            shift={-8}
                                          >
                                            <Menubar.SubTrigger
                                              class="menubar__sub-trigger"
                                              onClick={(e) =>
                                                onMenuSelected(
                                                  "/" +
                                                    [root, k, k2, k3].join("/")
                                                )
                                              }
                                            >
                                              {k3}
                                              <div class="dropdown-menu__item-right-slot">
                                                <BiSolidRightArrow />
                                              </div>
                                            </Menubar.SubTrigger>
                                            <Menubar.Portal>
                                              <Menubar.SubContent class="menubar__sub-content">
                                                <For each={Object.entries(v3)}>
                                                  {([k4, v4]) => (
                                                    <Switch>
                                                      <Match
                                                        when={
                                                          k4[0] != "_" &&
                                                          typeof v4 ===
                                                            "object" &&
                                                          v4 != null &&
                                                          Object.keys(
                                                            v4
                                                          ).filter(
                                                            (key) =>
                                                              key[0] != "_" &&
                                                              key != "key"
                                                          ).length != 0
                                                        }
                                                      >
                                                        <Menubar.Sub
                                                          overlap
                                                          gutter={4}
                                                          shift={-8}
                                                        >
                                                          <Menubar.SubTrigger
                                                            class="menubar__sub-trigger"
                                                            onClick={(e) =>
                                                              onMenuSelected(
                                                                "/" +
                                                                  [
                                                                    root,
                                                                    k,
                                                                    k2,
                                                                    k3,
                                                                    k4,
                                                                  ].join("/")
                                                              )
                                                            }
                                                          >
                                                            {k4}
                                                            <div class="dropdown-menu__item-right-slot">
                                                              <BiSolidRightArrow />
                                                            </div>
                                                          </Menubar.SubTrigger>
                                                          <Menubar.Portal>
                                                            <Menubar.SubContent class="menubar__sub-content">
                                                              <For
                                                                each={Object.entries(
                                                                  v4
                                                                )}
                                                              >
                                                                {([k5, v5]) => (
                                                                  <Switch>
                                                                    <Match
                                                                      when={
                                                                        k5[0] !=
                                                                          "_" &&
                                                                        typeof v5 ===
                                                                          "object" &&
                                                                        v5 !=
                                                                          null &&
                                                                        Object.keys(
                                                                          v5
                                                                        ).filter(
                                                                          (
                                                                            key
                                                                          ) =>
                                                                            key[0] !=
                                                                              "_" &&
                                                                            key !=
                                                                              "key"
                                                                        )
                                                                          .length !=
                                                                          0
                                                                      }
                                                                    >
                                                                      <Menubar.Item
                                                                        class="menubar__item"
                                                                        onSelect="setSelectedMenu"
                                                                      >
                                                                        {k5}
                                                                      </Menubar.Item>
                                                                    </Match>
                                                                    <Match
                                                                      when={
                                                                        k5[0] !=
                                                                          "_" &&
                                                                        typeof v5 ===
                                                                          "object" &&
                                                                        v5 !=
                                                                          null
                                                                      }
                                                                    >
                                                                      <Menubar.Item
                                                                        class="menubar__item"
                                                                        onClick={(
                                                                          e
                                                                        ) =>
                                                                          onMenuSelected(
                                                                            "/" +
                                                                              [
                                                                                root,
                                                                                k,
                                                                                k2,
                                                                                k3,
                                                                                k4,
                                                                                k5,
                                                                              ].join(
                                                                                "/"
                                                                              )
                                                                          )
                                                                        }
                                                                      >
                                                                        {k5}
                                                                      </Menubar.Item>
                                                                    </Match>
                                                                    s
                                                                  </Switch>
                                                                )}
                                                              </For>
                                                            </Menubar.SubContent>
                                                          </Menubar.Portal>
                                                        </Menubar.Sub>
                                                      </Match>
                                                      <Match
                                                        when={
                                                          k4[0] != "_" &&
                                                          typeof v4 ===
                                                            "object" &&
                                                          v4 != null
                                                        }
                                                      >
                                                        <Menubar.Item
                                                          class="menubar__item"
                                                          onSelect={() =>
                                                            onMenuSelected(
                                                              "/" +
                                                                [
                                                                  root,
                                                                  k,
                                                                  k2,
                                                                  k3,
                                                                  k4,
                                                                ].join("/")
                                                            )
                                                          }
                                                        >
                                                          {k4}
                                                        </Menubar.Item>
                                                      </Match>
                                                      s
                                                    </Switch>
                                                  )}
                                                </For>
                                              </Menubar.SubContent>
                                            </Menubar.Portal>
                                          </Menubar.Sub>
                                        </Match>
                                        <Match
                                          when={
                                            k3[0] != "_" &&
                                            typeof v3 === "object" &&
                                            v3 != null
                                          }
                                        >
                                          <Menubar.Item
                                            class="menubar__item"
                                            onSelect={() =>
                                              onMenuSelected(
                                                "/" +
                                                  [root, k, k2, k3].join("/")
                                              )
                                            }
                                          >
                                            {k3}
                                          </Menubar.Item>
                                        </Match>
                                        s
                                      </Switch>
                                    )}
                                  </For>
                                </Menubar.SubContent>
                              </Menubar.Portal>
                            </Menubar.Sub>
                          </Match>
                          <Match
                            when={
                              k2[0] != "_" &&
                              typeof v2 === "object" &&
                              v2 != null
                            }
                          >
                            <Menubar.Item
                              class="menubar__item"
                              onSelect={() => {
                                onMenuSelected("/" + [root, k, k2].join("/")),
                                  console.log([root, k, k2]);
                              }}
                            >
                              {k2}
                            </Menubar.Item>
                          </Match>
                        </Switch>
                      )}
                    </For>
                  </Menubar.Content>
                </Menubar.Portal>
              </Menubar.Menu>
            </Match>
          </Switch>
        )}
      </For>
    </Menubar>
  );
};

function SettingsPosthDlg(props) {
  return (
    <Dialog open={open()} onOpenChange={setOpen}>
      <Dialog.Portal>
        <Dialog.Overlay class="dialog__overlay" />
        <div class="dialog__positioner">
          <Dialog.Content class="dialog__content">
            <div class="dialog__header">
              <Dialog.Title class="dialog__title">POST with SSH</Dialog.Title>
              <Dialog.CloseButton class="dialog__close-button">
                <ImCross />
              </Dialog.CloseButton>
            </div>
            <Dialog.Description class="dialog__description">
              <form id="postwithssh" onsubmit="return false;">
                <TextField class="text-field">
                  <TextField.Label class="text-field__label">
                    HOST(:PORT) :
                  </TextField.Label>
                  <TextField.Input
                    class="text-field__input"
                    defaultValue="192.168.1.1:58022"
                    value="127.0.0.1:50822"
                    name="sshhost"
                    id="sshhost"
                    required={true}
                  />
                </TextField>
                <TextField class="text-field">
                  <TextField.Label class="text-field__label">
                    ID :{" "}
                  </TextField.Label>
                  <TextField.Input
                    class="text-field__input"
                    defaultValue=""
                    name="sshid"
                    id="sshid"
                    value="wj"
                    required={true}
                  />
                </TextField>
                <TextField class="text-field">
                  <TextField.Label class="text-field__label">
                    PW :{" "}
                  </TextField.Label>
                  <TextField.Input
                    type="password"
                    class="text-field__input"
                    defaultValue=""
                    name="sshpass"
                    id="sshpass"
                    required={true}
                  />
                </TextField>
                <br />
                <div>
                  <Button onclick={onSubmit} type="submit" class="button">
                    TEST
                  </Button>
                </div>
              </form>
            </Dialog.Description>
          </Dialog.Content>
        </div>
      </Dialog.Portal>
    </Dialog>
  );
}

function SettingsMenu(props) {
  return (
    <DropdownMenu>
      <DropdownMenu.Trigger class="dropdown-menu__trigger github">
        <span>Settings</span>
        <DropdownMenu.Icon class="dropdown-menu__trigger-icon"></DropdownMenu.Icon>
      </DropdownMenu.Trigger>
      <DropdownMenu.Portal>
        <DropdownMenu.Content class="dropdown-menu__content">
          <DropdownMenu.Item
            class="dropdown-menu__item"
            onSelect={() => {
              console.log(open);
              setOpen(1);
            }}
          >
            POST With SSH
          </DropdownMenu.Item>
          <DropdownMenu.Sub overlap gutter={4} shift={-8}>
            <DropdownMenu.SubTrigger class="dropdown-menu__sub-trigger">
              GitHub
              <div class="dropdown-menu__item-right-slot">
                <BiSolidRightArrow />
              </div>
            </DropdownMenu.SubTrigger>
            <DropdownMenu.Portal>
              <DropdownMenu.SubContent class="dropdown-menu__sub-content">
                <DropdownMenu.Item class="dropdown-menu__item">
                  Create Pull Request…
                </DropdownMenu.Item>
                <DropdownMenu.Item class="dropdown-menu__item">
                  View Pull Requests
                </DropdownMenu.Item>
                <DropdownMenu.Item class="dropdown-menu__item">
                  Sync Fork
                </DropdownMenu.Item>
                <DropdownMenu.Separator class="dropdown-menu__separator" />
                <DropdownMenu.Item class="dropdown-menu__item">
                  Open on GitHub
                </DropdownMenu.Item>
              </DropdownMenu.SubContent>
            </DropdownMenu.Portal>
          </DropdownMenu.Sub>
          <DropdownMenu.Separator class="dropdown-menu__separator" />
          <DropdownMenu.CheckboxItem class="dropdown-menu__checkbox-item">
            <DropdownMenu.ItemIndicator class="dropdown-menu__item-indicator">
              <CheckIcon />
            </DropdownMenu.ItemIndicator>
            Show Git Log
          </DropdownMenu.CheckboxItem>
          <DropdownMenu.CheckboxItem class="dropdown-menu__checkbox-item">
            <DropdownMenu.ItemIndicator class="dropdown-menu__item-indicator">
              <CheckIcon />
            </DropdownMenu.ItemIndicator>
            Show History
          </DropdownMenu.CheckboxItem>
          <DropdownMenu.Separator class="dropdown-menu__separator" />
          <DropdownMenu.Item
            class="dropdown-menu__item"
            onSelect={() =>
              window.open("https://github.com/bignikescar/blockkit")
            }
          >
            BKIT
          </DropdownMenu.Item>
          <DropdownMenu.Arrow />
        </DropdownMenu.Content>
      </DropdownMenu.Portal>
    </DropdownMenu>
  );
}

function Nav(props) {
  const menuTree = unwrap(tuiTree);
  var treetop = {};
  for (const [key, value] of Object.entries(menuTree)) {
    treetop = value;
    break;
  }

  return (
    <header class="header">
      <nav class="inner">
        <SettingsMenu />
        <MenuBar node={treetop} />
      </nav>
      <SettingsPosthDlg />
    </header>
  );
}

export default Nav;

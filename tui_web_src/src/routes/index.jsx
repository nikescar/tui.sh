import { Title } from "@solidjs/meta";
import {
  createSignal,
  createMemo,
  createResource,
  createEffect,
  onMount,
  onCleanup,
  For,
} from "solid-js";
import { unwrap } from "solid-js/store";
import Terminal from "../components/Terminal";
import VirtuaList from "../components/VirtuaList";
import LogFetcher from "../components/LogFetcher";
import { Button } from "@kobalte/core/button";
import { Tabs } from "@kobalte/core/tabs";
import "./index.css";
import {
  tuiTree,
  setTuiTree,
  selectedMenu,
  setSelectedMenu,
  findSubmenuFromTop,
} from "../store/yaml";
import AChart from "../components/AChart";
import Counter from "../components/Counter";
import CSVSelect from "../components/CSVSelect";
import PsEditor from "../components/PsEditor";
import { tuiReq, setTuiReq, fwdrequest } from "../../tui.net.lib";
import { status, setStatus } from "../store/server";

export default function Index() {
  const [selectedTab, setSelectedTab] = createSignal(0);
  const [tabs, setTabs] = createSignal([
    {
      id: "4",
      title: "Counter",
      component: "Counter",
      props: {
        address: "/",
        content: "Counter",
      },
    },
    {
      id: "2",
      title: "VirtuaList",
      component: "VirtuaList",
      props: {
        address: "/",
        content: "VirtuaList",
      },
    },
    {
      id: "3",
      title: "AChart",
      component: "AChart",
      props: {
        address: "/",
        content: "AChart",
      },
    },
    {
      id: "5",
      title: "CSVSelect",
      component: "CSVSelect",
      props: {
        address: "/",
        content: "CSVSelect",
      },
    },
    {
      id: "6",
      title: "PsEditor",
      component: "PsEditor",
      props: {
        address: "/",
        content: "PsEditor",
      },
    },
  ]);
  const newTabAdded = (el) => {
    setSelectedTab(el.id);
  };

  createEffect(() => {
    var menu = selectedMenu()["address"];
    if (menu != undefined && menu.length > 2) {
      var addrpart = menu.split("/");
      addrpart.shift();
      var smenu = findSubmenuFromTop(
        Object.entries(unwrap(tuiTree))[0][1],
        menu
      );
      setTabs((prev) => [
        {
          id: String(prev.length + 1),
          title: addrpart[addrpart.length - 1],
          component: "LogFetcher",
          props: {
            address: menu,
            content: "LogFetcher",
            submenu: smenu,
          },
        },
        ...prev,
      ]);
    }
    // changeServerStatus();
  });

  var reqObj = undefined;
  const fetchTuiNet = async () => {
    reqObj = await fwdrequest(0, {
      address: "/",
      content: "Check",
      submenu: "",
    });
    if (reqObj.step < 2) {
      setStatus(0); // tui_web.responder not working
    } else {
      setStatus(1);
    }
  };

  const [shouldFetch, setShouldFetch] = createSignal();
  const [data, { refetch }] = createResource(shouldFetch, fetchTuiNet);

  onMount(async () => {
    //check tui_web.responder working
    setShouldFetch(true);
  });

  const timer = setInterval(() => {
    if (reqObj) {
      if (reqObj.stepRepeated > 10) {
        clearInterval(timer);
      }
      if (reqObj.stepRepeated < 2) {
        refetch();
      }
    }
  }, 800);
  onCleanup(() => clearInterval(timer));

  const changeTab = (tabid) => {
    setSelectedTab(tabid);
  };

  const removeTab = () => {
    if (tabs().length > 1) {
      setTabs((prev) =>
        prev.filter((x) => {
          return x.id != selectedTab();
        })
      );

      // setTabs((prev) => prev.slice(0, -1));
    }
  };

  const pinTab = () => {
    // console.log("pin tab");
  };

  const gotoSubmenu = (evt) => {
    var smenu = evt.target.innerText;
    var addrpart = evt.target.attributes.address.value.split("/");
    addrpart.shift();
    var newmenu = [...addrpart, smenu];
    setSelectedMenu({
      address: "/" + newmenu.join("/"),
    });
  };

  const gotoParentmenu = (evt) => {
    var addrpart = evt.target.attributes.address.value.split("/");
    addrpart.pop();
    addrpart.shift();
    setSelectedMenu({
      address: "/" + addrpart.join("/"),
    });
  };

  return (
    <main>
      <Title>tui_web</Title>
      <Show
        when={status()}
        fallback={
          <div>
            tui_web_responder not connected. Please enable server and refresh.
          </div>
        }
      >
        <Tabs
          aria-label="Main navigation"
          class="tabs "
          orientation="vertical"
          value={selectedTab()}
          onChange={changeTab}
        >
          <Tabs.List class="tabs__list ">
            <For each={tabs()}>
              {(tab, index) => (
                <Tabs.Trigger
                  class={"tabs__trigger"}
                  ref={newTabAdded}
                  value={tab.id}
                >
                  {tab.title}
                </Tabs.Trigger>
              )}
            </For>
            <Tabs.Indicator class="tabs__indicator" />
          </Tabs.List>
          <For each={tabs()}>
            {(tab) => (
              <Tabs.Content class="tabs__content" value={tab.id}>
                <button disabled>{tab.props.address}</button>|
                <button onClick={removeTab}>Close</button>
                <button disabled onClick={pinTab}>
                  Pin
                </button>
                |
                {tab.props.address.split("/").length > 1 ? (
                  <>
                    <button {...tab.props} onClick={gotoParentmenu}>
                      Up
                    </button>
                    |
                  </>
                ) : (
                  <></>
                )}
                <For each={tab.props.submenu}>
                  {(smenu, index) => (
                    <button {...tab.props} onClick={gotoSubmenu}>
                      {smenu}
                    </button>
                  )}
                </For>
                {tab.component == "Terminal" && <Terminal {...tab.props} />}
                {tab.component == "VirtuaList" && <VirtuaList {...tab.props} />}
                {tab.component == "LogFetcher" && <LogFetcher {...tab.props} />}
                {tab.component == "AChart" && <AChart {...tab.props} />}
                {tab.component == "Counter" && <Counter {...tab.props} />}
                {tab.component == "CSVSelect" && <CSVSelect {...tab.props} />}
                {/* {tab.component == "LogViewer" && <LogViewer {...tab.props} />} */}
                {tab.component == "PsEditor" && (
                  <PsEditor {...tab.props} readpath="/var/log/access.log" />
                )}
              </Tabs.Content>
            )}
          </For>
        </Tabs>
      </Show>
    </main>
  );
}

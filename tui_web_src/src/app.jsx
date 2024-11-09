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
import { Switch, Match } from "solid-js";
import { MetaProvider, Title } from "@solidjs/meta";
import { Router } from "@solidjs/router";
import { FileRoutes } from "@solidjs/start/router";
import { Suspense } from "solid-js";
import Nav from "./components/nav";
import "./app.css";
import { parse, stringify } from "yaml";
import {
  tuiTree,
  setTuiTree,
  selectedMenu,
  setSelectedMenu,
  tuiConfig,
  setTuiConfig,
  parseConfig,
} from "./store/yaml";

export default function App(props) {
  const fetchYaml = async (id) => {
    // fetch yaml
    const r = await fetch("/index.yaml");
    var treeText = await r.text();
    var tree = parse(treeText);
    var tConfig = parseConfig(tree);
    // get config
    setTuiTree({ tree: tree }); // set site wide menu tree
    setTuiConfig("config", tConfig); // set site wide config

    return [tree];
  };

  const [shouldFetch, setShouldFetch] = createSignal();
  const [data, { refetch }] = createResource(shouldFetch, fetchYaml);
  onMount(() => {
    setShouldFetch(true);
  });

  const error = (props) => {
    console.log(
      "cant find index.yaml. if you run on dev env, please run npm run wprep to copy tui.sh.yaml to .tui_web/index.yaml."
    );
    console.log(props);
  };

  return (
    <Router
      root={(props) => (
        <MetaProvider>
          <Show when={data.loading}>
            <p>Loading...</p>
          </Show>
          <Switch>
            <Match when={data.error}>
              <span>Error: {error(data.error)}</span>
            </Match>
            <Match when={data()}>
              <Nav />
              <Suspense>{props.children}</Suspense>
            </Match>
          </Switch>
        </MetaProvider>
      )}
    >
      <FileRoutes />
    </Router>
  );
}
